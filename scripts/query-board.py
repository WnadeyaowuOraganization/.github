#!/usr/bin/env python
import os
import json, subprocess, sys, urllib.request
HOME_DIR = os.environ.get('HOME_DIR', '/home/ubuntu')

PROJECT_ID = "PVT_kwDOD3gg584BTjK2"
VALID_STATUSES = {"Plan", "Todo", "In Progress", "Done", "pause", "Fail", "all"}
STATUS_ORDER = {"Fail": 0, "pause": 1, "Plan": 2, "Todo": 3, "In Progress": 4, "Done": 5}

def get_token():
    r = subprocess.run(["bash", f"{HOME_DIR}/projects/.github/scripts/get-gh-token.sh"], capture_output=True, text=True)
    t = r.stdout.strip()
    if not t:
        print("ERROR: failed to get token", file=sys.stderr)
        sys.exit(1)
    return t

def run_query(token, query, variables=None):
    body = {"query": query}
    if variables:
        body["variables"] = variables
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        "https://api.github.com/graphql",
        data=data,
        headers={"Authorization": "bearer " + token, "Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))

def fetch_items(token, status_filter=None):
    base_q = 'query($projectId: ID!, $first: Int!, $after: String%(filter_arg)s) { node(id: $projectId) { ... on ProjectV2 { items(first: $first, after: $after%(query_arg)s) { pageInfo { hasNextPage endCursor } nodes { id fieldValues(first: 20) { nodes { ... on ProjectV2ItemFieldSingleSelectValue { name field { ... on ProjectV2SingleSelectField { name } } } } } content { ... on Issue { number title state labels(first: 10) { nodes { name } } } } } } } } }'
    fa = ", $query: String" if status_filter else ""
    qa = ", query: $query" if status_filter else ""
    q = base_q % {"filter_arg": fa, "query_arg": qa}
    vs = {"projectId": PROJECT_ID, "first": 100}
    if status_filter:
        vs["query"] = 'status:"' + status_filter + '"'
    items = []
    cursor = None
    while True:
        if cursor:
            vs["after"] = cursor
        elif "after" in vs:
            del vs["after"]
        res = run_query(token, q, vs)
        if "errors" in res:
            for e in res["errors"]:
                print("  " + str(e.get("message", e)), file=sys.stderr)
            sys.exit(1)
        nd = res["data"]["node"]["items"]
        items.extend(nd.get("nodes") or [])
        pi = nd["pageInfo"]
        if pi["hasNextPage"]:
            cursor = pi["endCursor"]
        else:
            break
    return items

def get_status(item):
    for fv in item.get("fieldValues", {}).get("nodes", []):
        fi = fv.get("field")
        if fi and fi.get("name") == "Status":
            return fv.get("name", "")
    return ""

def get_labels(c):
    if not c:
        return []
    return [l["name"] for l in (c.get("labels", {}).get("nodes") or [])]

def main():
    status = sys.argv[1] if len(sys.argv) > 1 else "all"
    if status not in VALID_STATUSES:
        print("Usage: " + sys.argv[0] + " [status]")
        print("  Valid: " + ", ".join(sorted(VALID_STATUSES)))
        sys.exit(1)
    token = get_token()
    sf = status if status != "all" else None
    items = fetch_items(token, sf)
    parsed = []
    for item in items:
        c = item.get("content")
        if not c or not isinstance(c, dict):
            continue
        if c.get("state") == "CLOSED":
            continue
        bs = get_status(item)
        labels = get_labels(c)
        mod = next((l.replace("module:", "") for l in labels if l.startswith("module:")), "")
        pri = next((l for l in labels if l.startswith("priority/")), "")
        parsed.append({"s": bs, "n": c.get("number", 0), "t": c.get("title", ""),
                    "m": mod, "p": pri, "tf": "status:test-failed" in labels})
    parsed.sort(key=lambda x: (STATUS_ORDER.get(x["s"], 99), x["n"]))
    cs = None
    for item in parsed:
        if item["s"] != cs:
            cs = item["s"]
            cnt = sum(1 for i in parsed if i["s"] == cs)
            print()
            print("--- " + cs + " (" + str(cnt) + ") ---")
        mod = item["m"].ljust(10) if item["m"] else " " * 10
        pri = item["p"].ljust(12) if item["p"]  else " " * 12
        tf = " [TEST-FAILED]" if item["tf"] else ""
        print("  #" + str(item["n"]).ljust(5) + " " + mod + " " + pri + " " + item["t"] + tf)
    if not parsed:
        print("No open issues for status: " + status)
    print()
    print("Total: " + str(len(parsed)) + " issues")

if __name__ == "__main__":
    main()
