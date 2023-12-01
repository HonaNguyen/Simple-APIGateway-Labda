import json

from src.train import Classifier


def is_valid_number(value):
    try:
        float(value)
        return True
    except ValueError:
        return False


# def predict(sepal_length, sepal_width, petal_length, petal_width):
#     a = 2
#     b = 3
#     c = 4
#     d = 5
#     e = 6

#     res = (
#         a * sepal_length**4
#         + b * sepal_width**3
#         + c * petal_length**2
#         + d * petal_width
#         + e
#     )
#     return res


def predict(sepal_length, sepal_width, petal_length, petal_width):
    dt = list(map(float, [sepal_length, sepal_width, petal_length, petal_width]))

    req = {"data": [dt]}

    classify = Classifier()
    return classify.load_and_test(req)


def lambda_handler(event, context):
    params = event["queryStringParameters"]

    sepal_length = params.get("sepal_length", 0)
    sepal_width = params.get("sepal_width", 0)
    petal_length = params.get("petal_length", 0)
    petal_width = params.get("petal_width", 0)

    if not all(
        is_valid_number(val)
        for val in [sepal_length, sepal_width, petal_length, petal_width]
    ):
        return {
            "statusCode": 400,
            "body": json.dumps(
                "Invalid input parameters. Please provide valid numbers."
            ),
        }

    sepal_length = float(sepal_length)
    sepal_width = float(sepal_width)
    petal_length = float(petal_length)
    petal_width = float(petal_width)

    print(event)

    # result = {"Message": "Hello Nancy"}
    result = predict(sepal_length, sepal_width, petal_length, petal_width)

    return {"statusCode": 200, "body": json.dumps(result)}
