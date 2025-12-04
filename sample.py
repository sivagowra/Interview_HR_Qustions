import boto3

s3 = boto3.client("s3")

response = s3.list_buckets()

for bucket in response['Buckets']:
    print(bucket['Name'])

ec2 = boto3.client("ec2")

response = ec2.describe_instances()

for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        print(instance['InstanceId'], instance['State']['Name'])
        
        