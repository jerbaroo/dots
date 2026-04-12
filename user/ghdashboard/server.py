import flask
import requests
import os
import subprocess
import sys
from typing import Optional

# Data sources ##########################################################################


with open("query.graphql", "r") as f:
    query = f.read()


read_token_path = None
token = None


def read_token(raise_):
    try:
        global token
        if token:
            print("read_token: token previously read")
            return token
        else:
            print("read_token: no token, attempting to read GITHUB_TOKEN")
            code, token_ = subprocess.getstatusoutput(f"sh {read_token_path}")
            if code == 0:
                token = token_
            else:
                raise Exception(
                    f"When executing '{read_token_path}' got error code {code} and output: {token_}"
                )
        if token and isinstance(token, str):
            print("read_token: token read")
            return token
        else:
            raise Exception(f"read_token: token is '{token}'")
    except Exception as e:
        if raise_:
            print(f"read_token: raising {e}")
            raise e
        else:
            print(f"read_token: NOT raising {e}")


def github_data(limit: Optional[int], order: Optional[str], org: Optional[str]):
    query_ = (
        query.replace("<<limit>>", str(limit) if limit else "100")
        .replace("<<order>>", order if order else "last")
        .replace("<<org>>", f"org:{org} " if org else "")
    )
    headers = {"Authorization": f"Bearer {read_token(raise_=True)}"}
    response = requests.post(
        "https://api.github.com/graphql", json={"query": query_}, headers=headers
    )
    return response.json()


# Flask app #############################################################################

app = flask.Flask(__name__)


def client_error(msg, code):
    return {"error": msg}, code


@app.route("/data")
def data():
    try:
        limit = flask.request.args.get("limit")
        order = flask.request.args.get("order")
        org = flask.request.args.get("org")
        print(f"limit={limit} org={org}")
        return {"github": github_data(limit=limit, order=order, org=org)}
    except Exception as e:
        return client_error(str(e), 500)


@app.route("/")
def index():
    return flask.send_from_directory(".", "index.html")


if __name__ == "__main__":
    port = sys.argv[1]
    read_token_path = sys.argv[2]
    print(f"port={port}, read_token_path={read_token_path}")
    app.run(debug=True, port=port)
