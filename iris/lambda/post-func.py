import json


def lambda_handler(event, context):
    # TODO implement
    print(event)
    return {
        "statusCode": 200,
        "body": json.dumps("Hello from AWS with POST Method!"),
    }