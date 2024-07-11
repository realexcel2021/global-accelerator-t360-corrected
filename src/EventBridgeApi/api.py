import json
import base64
from botocore.exceptions import ClientError
import boto3
import logging
import traceback
from psycopg2.extras import RealDictCursor
import psycopg2
import os


def enable_logging():
    root = logging.getLogger()
    if root.handlers:
        for handler in root.handlers:
            root.removeHandler(handler)
    logging.basicConfig(format='%(asctime)s %(message)s', level=logging.DEBUG)


enable_logging()


def get_secret():
    secret_name = 'database-terraform_secret_qwq'
    region_name = "us-east-1"
    secret = None
    # Create a Secrets Manager client
    session = boto3.session.Session()
    print("before secret")
    endpoint_url = "https://secretsmanager.us-east-1.amazonaws.com"
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name,
        endpoint_url=endpoint_url
    )

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
    except Exception as e:
        raise e
    else:
        # Decrypts secret using the associated KMS CMK.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
    print("after secret")
    return json.loads(secret)  # returns the secret as dictionary


def cors_headers():
    return {
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,HEAD,PUT,DELETE,PATCH'
    }


def get_db_connection():

    connection = None
    secret_result = get_secret()
    username = secret_result['username']
    password = secret_result['password']
    dbname = secret_result['dbname']
    host = secret_result['host']
    port = secret_result['port']

    try:
        print("Connecting to DB and Push statements")
        connection = psycopg2.connect(
            host=host,
            database=dbname,
            user=username,
            password=password,
            port=port)
    except (Exception, psycopg2.Error) as error:
        print("Failed to init DB connection", error)

    return connection




def revenue_codes(event, context):

    result = ''
    status_code = 500
    try:
        db_connection = get_db_connection()
        query = """CREATE TABLE revenue_codes (
        id BIGSERIAL PRIMARY KEY,
        ext_site_id VARCHAR(2) NOT NULL,
        gc_revenue_code_id INTEGER,
        source_id INTEGER,
        revenue_code_id VARCHAR(50),
        ext_revenue_code_id VARCHAR(50),
        revenue_code_name VARCHAR(255),
        priority INTEGER,
        draw_down_amount DECIMAL,
        rc_value1 VARCHAR(255),
        rc_value2 VARCHAR(255),
        rc_value3 VARCHAR(255),
        rc_value4 VARCHAR(255),
        prop_data JSONB,
        is_calc_draw_down BOOLEAN
        );"""

        cursor = db_connection.cursor(cursor_factory=RealDictCursor)
        cursor.execute(query)
        db_connection.commit()
        status_code = 200

    except Exception as error:
        print("Error  creating revenue_codes table: " + str(error))
        traceback.print_exc()
        result = str(error)

    response = {
        "statusCode": status_code,
        'headers': cors_headers(),
        "body": json.dumps(result, indent=2, sort_keys=True, default=str)
    }

    return response




def create_item(event, context):

    result = ''
    status_code = 500
    print(event)
    try:
        wholeevent = json.loads(event["Records"][0]["body"])
        input_body = wholeevent["detail"]
        if input_body:
            json_param = input_body
            ext_site_id = json_param["ExtSiteID"]
            gc_revenue_code_id = json_param["Data"]["gc_revenue_code_id"]
            source_id = json_param["Data"]["source_id"]
            revenue_code_id = json_param["Data"]["RevenueCodeID"]
            ext_revenue_code_id = json_param["Data"]["ExtRevenueCodeID"]
            revenue_code_name = json_param["Data"]["RevenueCodeName"]
            priority = json_param["Data"]["Priority"]
            draw_down_amount = json_param["Data"]["DrawDownAmount"]
            rc_value1 = json_param["Data"]["RCValue1"]
            rc_value2 = json_param["Data"]["RCValue2"]
            rc_value3 = json_param["Data"]["RCValue3"]
            rc_value4 = json_param["Data"]["RCValue4"]
            prop_data = json_param["Data"]["PropData"]
            is_calc_draw_down = json_param["Data"]["IsCalcDrawDown"]

            db_connection = get_db_connection()

            query = """INSERT INTO revenue_codes (ext_site_id, gc_revenue_code_id, source_id, revenue_code_id, ext_revenue_code_id, revenue_code_name, priority, draw_down_amount, rc_value1, rc_value2, rc_value3, rc_value4, prop_data, is_calc_draw_down) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);"""
            cursor = db_connection.cursor(cursor_factory=RealDictCursor)
            cursor.execute(query, (ext_site_id, gc_revenue_code_id, source_id, revenue_code_id, ext_revenue_code_id, revenue_code_name, priority, draw_down_amount, rc_value1, rc_value2, rc_value3, rc_value4, prop_data, is_calc_draw_down))
            db_connection.commit()
            status_code = 200
        else:
            result = "Error, incorrect post body"
            status_code = 400
    except Exception as error:
        print("Error creating revenue" + str(error))
        traceback.print_exc()
        result = str(error)

    response = {
        "statusCode": status_code,
        'headers': cors_headers(),
        "body": json.dumps(result, indent=2, sort_keys=True, default=str)
    }

    return response

    
class RevenueCode:
  """
  It represents a revenue code.
  """

  def __init__(self, record):
    """
    Initializes the RevenueCode from the database record.

    :param record: The database record.
    """

    self.id = record['id']
    self.ext_site_id = record['ext_site_id']
    self.gc_revenue_code_id = record['gc_revenue_code_id']  # Handle potential null value
    self.source_id = record['source_id']  # Handle potential null value
    self.revenue_code_id = record['revenue_code_id']  # Handle potential null value
    self.ext_revenue_code_id = record['ext_revenue_code_id']  # Handle potential null value
    self.revenue_code_name = record['revenue_code_name']  # Handle potential null value
    self.priority = record['priority']  # Handle potential null value
    self.draw_down_amount = record['draw_down_amount']  # Handle potential null value
    self.rc_value1 = record['rc_value1']  # Handle potential null value
    self.rc_value2 = record['rc_value2']  # Handle potential null value
    self.rc_value3 = record['rc_value3']  # Handle potential null value
    self.rc_value4 = record['rc_value4']  # Handle potential null value
    self.prop_data = record['prop_data']  # Handle potential null value
    self.is_calc_draw_down = record['is_calc_draw_down']  # Handle potential null value

  def to_dict(self):
    """
    Returns a dictionary representation of the RevenueCode object.
    """

    return {
      'id': self.id,
      'ext_site_id': self.ext_site_id,
      'gc_revenue_code_id': self.gc_revenue_code_id,
      'source_id': self.source_id,
      'revenue_code_id': self.revenue_code_id,
      'ext_revenue_code_id': self.ext_revenue_code_id,
      'revenue_code_name': self.revenue_code_name,
      'priority': self.priority,
      'draw_down_amount': self.draw_down_amount,
      'rc_value1': self.rc_value1,
      'rc_value2': self.rc_value2,
      'rc_value3': self.rc_value3,
      'rc_value4': self.rc_value4,
      'prop_data': self.prop_data,
      'is_calc_draw_down': self.is_calc_draw_down,
    }




def get_item(event, context):

    result = ''
    status_code = 500
    remittances = list()
    try:
        db_connection = get_db_connection()
        query = """SELECT * FROM revenue_codes"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)
        cursor.execute(query)
        records = cursor.fetchall()
        print(records)
        for record in records:
            remittance = RevenueCode(record)
            remittances.append(remittance)
        if remittances:
            result = [remittance.to_dict() for remittance in remittances]
        status_code = 200
    except Exception as error:
        print("Error getting remittances", error)
        traceback.print_exc()
        result = str(error)

    response = {
        "statusCode": status_code,
        'headers': cors_headers(),
        "body": json.dumps(result, indent=2, sort_keys=True, default=str)
    }

    return response

