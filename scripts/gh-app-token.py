#!/usr/bin/env python3
"""Generate GitHub App Installation Token for gh CLI.

Usage:
    export GH_TOKEN=$(python3 /home/ubuntu/projects/.github/scripts/gh-app-token.py)
    gh issue list --repo WnadeyaowuOraganization/wande-play

Config: $HOME_DIR/projects/.github/scripts/github-app/config.env
Key:    $HOME_DIR/projects/.github/scripts/github-app/private-key.pem
"""

import json
import os
import sys
import time
import urllib.request
import urllib.error

HOME_DIR = os.environ.get('HOME_DIR', '/home/ubuntu')

# --- Config ---
CONFIG_DIR = f"{HOME_DIR}/projects/.github/scripts/github-app"
KEY_PATH = os.path.join(CONFIG_DIR, "private-key.pem")
CONFIG_PATH = os.path.join(CONFIG_DIR, "config.env")


def load_config():
    """Load APP_ID and INSTALLATION_ID from config.env."""
    config = {}
    with open(CONFIG_PATH) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                config[k.strip()] = v.strip()
    return config



def generate_jwt(app_id, key_path):
    """Generate JWT signed with RS256 using the App's private key."""
    import hashlib
    import hmac
    import struct

    with open(key_path, "rb") as f:
        key_data = f.read()

    # Use PyJWT if available, otherwise fall back to manual RSA
    try:
        import jwt as pyjwt
        now = int(time.time())
        payload = {
            "iat": now - 60,
            "exp": now + (10 * 60),  # 10 minutes max
            "iss": str(app_id),
        }
        return pyjwt.encode(payload, key_data, algorithm="RS256")
    except ImportError:
        pass

    # Fallback: use cryptography library
    try:
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import padding
        import base64

        private_key = serialization.load_pem_private_key(key_data, password=None)
        now = int(time.time())

        # Build JWT manually
        header = base64url_encode(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
        payload_data = json.dumps({
            "iat": now - 60,
            "exp": now + (10 * 60),
            "iss": str(app_id),
        }).encode()
        payload_b64 = base64url_encode(payload_data)

        signing_input = header + b"." + payload_b64
        signature = private_key.sign(signing_input, padding.PKCS1v15(), hashes.SHA256())
        sig_b64 = base64url_encode(signature)

        return (signing_input + b"." + sig_b64).decode()
    except ImportError:
        print("ERROR: Need PyJWT or cryptography library. Install: pip install PyJWT cryptography", file=sys.stderr)
        sys.exit(1)


def base64url_encode(data):
    """Base64url encode without padding."""
    import base64
    if isinstance(data, str):
        data = data.encode()
    return base64.urlsafe_b64encode(data).rstrip(b"=")


def check_graphql_remaining(token):
    """Check GraphQL rate limit remaining via REST (doesn't consume GraphQL quota)."""
    req = urllib.request.Request(
        "https://api.github.com/rate_limit",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
            return data.get("resources", {}).get("graphql", {}).get("remaining", 0)
    except Exception:
        return 0


def get_installation_token(jwt_token, installation_id):
    """Exchange JWT for an installation access token."""
    url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
    req = urllib.request.Request(
        url,
        method="POST",
        headers={
            "Authorization": f"Bearer {jwt_token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
            return data["token"], data.get("expires_at", "")
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"ERROR: GitHub API {e.code}: {body}", file=sys.stderr)
        sys.exit(1)



def main():
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    TOKEN_DIR = os.path.join(SCRIPT_DIR, "tokens")

    def _read_pat(name):
        """读取 tokens/<name>.pat 文件内容。"""
        path = os.path.join(TOKEN_DIR, f"{name}.pat")
        try:
            token = open(path).read().strip()
            if token:
                return token
        except Exception:
            pass
        print(f"ERROR: token file not found: {path}", file=sys.stderr)
        sys.exit(1)

    # 传参模式：python3 gh-app-token.py <name>  → 直接返回 tokens/<name>.pat
    if len(sys.argv) == 2:
        print(_read_pat(sys.argv[1]))
        return

    # 无参数模式：编程CC使用 App Installation Token
    try:
        config = load_config()
        app_id = config["APP_ID"]
        installation_id = config["INSTALLATION_ID"]

        jwt_token = generate_jwt(app_id, KEY_PATH)
        app_token, _ = get_installation_token(jwt_token, installation_id)

        # 检查 GraphQL 额度，耗尽则 fallback 到 weiping PAT
        graphql_remaining = check_graphql_remaining(app_token)
        if graphql_remaining > 0:
            print(app_token)
            return
        print("App token GraphQL exhausted, falling back to weiping.pat", file=sys.stderr)
    except Exception:
        pass

    # Fallback: weiping PAT
    print(_read_pat("weiping"))


if __name__ == "__main__":
    main()
