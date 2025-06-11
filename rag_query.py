import os
import boto3
from flask import Flask, request, jsonify

# Create a Flask application
app = Flask(__name__)

# Set the SageMaker endpoint name as an environment variable
SAGEMAKER_ENDPOINT = os.environ.get('SAGEMAKER_ENDPOINT')

# Initialize the SageMaker runtime client
sagemaker_runtime = boto3.client('sagemaker-runtime', region_name='us-west-2')

# Route to handle inference requests
@app.route('/inference', methods=['POST'])
def perform_inference():
    input_data = request.json.get('input_data')
    
    # Send the input data to the SageMaker endpoint
    response = sagemaker_runtime.invoke_endpoint(
        EndpointName=SAGEMAKER_ENDPOINT,
        Body=input_data,
        ContentType='application/json'
    )
    
    # Retrieve the inference response from SageMaker
    result = response['Body'].read().decode('utf-8')

    # Return the inference result to the client
    return jsonify({'result': result})

# Route to handle file uploads for knowledge base
@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part in the request'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    bucket_name = os.environ.get('UPLOAD_BUCKET')
    if not bucket_name:
        return jsonify({'error': 'UPLOAD_BUCKET environment variable not set'}), 500

    s3_client = boto3.client('s3')
    s3_client.upload_fileobj(file, bucket_name, file.filename)

    return jsonify({'message': f'File {file.filename} uploaded to {bucket_name}'})

# Health check route
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    # Run the Flask app on port 8080
    app.run(host='0.0.0.0', port=8080)
