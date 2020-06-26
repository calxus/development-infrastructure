import boto3
import base64
import json
import jinja2
from botocore.exceptions import ClientError


def main():

    secret_name = "development"
    region_name = "eu-west-1"
    secret = "{}"

    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        print(e)
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            raise e
    else:
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
            
        config_data = json.loads(secret)
    
        with open('terraform.tf.j2') as in_template:
            template = jinja2.Template(in_template.read())
        with open('terraform.tf', 'w+') as terraform_tf:
            terraform_tf.write(template.render(config_data))
        with open('terraform.tfvars.j2') as in_template:
            template = jinja2.Template(in_template.read())
        with open('terraform.tfvars', 'w+') as terraform_tfvars:
            terraform_tfvars.write(template.render(config_data))
        print("Terraform config successfully created")


if __name__ == "__main__":
    main()