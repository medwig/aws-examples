By default lambda functions and EC2 instances are assigned an ip address at random. Sometimes we want to give our functions a consistent IP address, for example when whitelisting calls to a client API. An elastic IP (eip) give this functionality. Here's an example of creating an elastic ip, creating a lambda function with that eip allocated, and proving http calls it makes to the internet originate from that ip address.

To start, clone the repo with the source code:

`$ git clone https://github.com/medwig/aws-examples.git`

`$ cd aws-examples/elastic-ip`

We won't be allocating the eip directly to a lambda function, instead we deploy the lambda to a private subnet in a VPC, with a NAT gateway that allows outgoing access to the internet. We allocate the eip to this NAT gateway, and this was all private subnet instances route through the NAT and share this ip address.

To demo this, we'll need a vpc with private subnets, a NAT gateway attached, and a routing table to direct all outgoing traffic from the private subnets through the NAT gateway. We'll use Terraform to deploy this, and the standard vpc module makes setting all this up a snap:

### 1. Deploy VPC architecture with Terraform
`$ terraform apply`

In addition to the vpc infra, the terraform code also defines a few variables to be exported to SSM. This will allow them to be accessed from outside of Terraform, in our case by the Serverless framework we will use to deploy our lambda function into the private subnet we just created.

### 2. Confirm SSM variables present
`$ aws ssm get-parameters --names /vpc/eip`
```
{
    "Parameters": [
        {
            "Name": "/vpc/eip",
            "Type": "String",
            "Value": "x.xx.xxx.xx",
            "Version": 1,
        }
    ]
}
```

Now that the SSM variables are confirmed to work, we'll deploy our lambda. The function is extremely simple - it calls `ipconfig.me` to determine it's ip address and returns that value.

`$ cat handler.py`
```
import urllib.request

def get_ip(event, context):
    with urllib.request.urlopen('https://ifconfig.me/') as f:
        response = f.read().decode('utf')
    return response

```

Test this method out by calling it from the command line, returning your local ip address:

`$ sls invoke local -f get_ip`
```
xxx.xx.xxx.xx
```

Note that the `serverless.yml` service definition references the SSM vars we created to deploy the lambda function in the private subnets that Terraform created.

`$ cat serverless.yml`
```
service: tmp

provider:
  name: aws
  runtime: python3.7
  region: us-east-2

  vpc:
    securityGroupIds:
      - ${ssm:/vpc/security_group/default}
    subnetIds:
      "Fn::Split":
        - ','
        - ${ssm:/vpc/subnets/private}

functions:
  get_ip:
    handler: handler.get_ip

```

Deploy the lambda function:
### 3. Create serverless function
`$ sls deploy`


### 4. Invoke serverless function
`$ sls invoke -f get_ip`

This invokes the lambda function in the cloud (note the lack of `local` in the invoke call) to get the ip address it uses to make calls to the internet.

The lambda function should return an ip address equal to the ip address in the SSM variable - success!
