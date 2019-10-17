import urllib.request


def get_ip(event, context):
    with urllib.request.urlopen('https://ifconfig.me/') as f:
        resp = f.read().decode('utf')
    return resp

