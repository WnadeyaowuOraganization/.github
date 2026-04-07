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

# Token cache file (avoid regenerating if still valid)
CACHE_PATH = os.path.join(CONFIG_DIR, ".token-cache.json")
CACHE_MARGIN_SECONDS = 600  # refresh 10 min before expiry


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


def read_cached_token():
    """Return cached token if still valid."""
    if not os.path.exists(CACHE_PATH):
        return None
    try:
        with open(CACHE_PATH) as f:
            cache = json.load(f)
        # Check expiry (ISO 8601 → unix timestamp approximation)
        expires_at = cache.get("expires_at", "")
        if expires_at:
            from datetime import datetime, timezone
            exp = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
            now = datetime.now(timezone.utc)
            remaining = (exp - now).total_seconds()
            if remaining > CACHE_MARGIN_SECONDS:
                return cache["token"]
    except Exception:
        pass
    return None


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


def save_cache(token, expires_at):
    """Cache the token."""
    try:
        with open(CACHE_PATH, "w") as f:
            json.dump({"token": token, "expires_at": expires_at}, f)
        os.chmod(CACHE_PATH, 0o600)
    except Exception:
        pass


def main():
    # Try cache first
    cached = read_cached_token()
    if cached:
        print(cached)
        return

    # Load config
    config = load_config()
    app_id = config["APP_ID"]
    installation_id = config["INSTALLATION_ID"]

    # Generate JWT
    jwt_token = generate_jwt(app_id, KEY_PATH)

    # Exchange for installation token
    token, expires_at = get_installation_token(jwt_token, installation_id)

    # Cache it
    save_cache(token, expires_at)

    # Output token (for use in $(...) substitution)
    print(token)


if __name__ == "__main__":
    main()
