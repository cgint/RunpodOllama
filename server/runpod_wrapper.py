import runpod
import httpx
import traceback
import os

concurrency_max = int(os.getenv("CONCURRENCY_MAX", 6))
request_timeout = float(os.getenv("REQUEST_TIMEOUT", 300.0))

limits = httpx.Limits(max_connections=concurrency_max, max_keepalive_connections=concurrency_max)
client = httpx.AsyncClient(verify=False, limits=limits, timeout=request_timeout)

debug = os.getenv("DEBUG", "false")

def print_if_debug(message):
    if debug != "false":
        print(message)

async def handler(job):
    try:
        base_url = "http://0.0.0.0:11434"
        input = job['input']
        print_if_debug(f"Input: {input}")
        if 'url_path' not in input:
            raise Exception(f"Property url_path is required but not found in job-keys {input.keys()}")
        url_path = input['url_path']
        if url_path not in ['/api/chat', '/api/generate']:
            raise Exception(f"Invalid url_path: {url_path}")
        response = await client.post(
            url=f"{base_url}{url_path}",
            headers={"Content-Type": "application/json"},
            json=input,
        )
        response.encoding = "utf-8"

        result = response.json()
        print_if_debug(f"Result: {result}")
        return result
    except Exception as e:
        print("Error:", str(e))
        print("Error occurred:")
        print(traceback.format_exc())
        return {"error": str(e)}


runpod.serverless.start({
    "handler": handler,
    "concurrency_modifier": lambda _: concurrency_max
    })
