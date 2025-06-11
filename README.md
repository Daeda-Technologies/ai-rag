## Explanation of Key Components:

### SageMaker Model and Endpoint:
We define a **SageMaker model** using a specified **LLM inference image** and model data from **S3**. The model is deployed to a **SageMaker Endpoint** with **Elastic Scaling**.

### Elastic Scaling:
The setup includes **Auto Scaling policies** for the SageMaker Endpoint, using **Target Tracking** based on invocation metrics (e.g., "Invocations Per Instance"). The auto-scaling will adjust the number of instances based on traffic demand.

### VPC Setup:
The endpoint, subnets, and security groups are all provisioned inside a **VPC**, similar to the previous use case, ensuring security by restricting access to private network communication.

### IAM Roles:
IAM roles and policies are defined to ensure the SageMaker model and Lambda (if needed) have access to **S3** and **CloudWatch Logs**.

### Auto Scaling Policies:
Two policies are set up to handle scaling:

- **Scale Up** when the load on instances exceeds a defined threshold.
- **Scale Down** when the load drops below a certain level.

This infrastructure is flexible for scaling SageMaker endpoints based on demand, ensuring high availability and cost efficiency for LLM inference tasks.

## Explanation of Key Components:

### Flask API:
The Python application is a simple Flask API that takes input from the user, sends it to the SageMaker endpoint, and returns the inference result.

### Boto3 for SageMaker Interaction:
The `boto3` library is used to interact with the SageMaker endpoint. The API sends input data to the endpoint and retrieves the inference response.

### EKS Deployment:
The application is deployed to an EKS cluster using a Kubernetes Deployment and is exposed via a LoadBalancer service for external access.

### SageMaker Endpoint:
The environment variable `SAGEMAKER_ENDPOINT` is used to specify the SageMaker endpoint that the application will communicate with. You need to replace `your-sagemaker-endpoint-name` with the actual endpoint name.

This setup allows you to run the client application on **EKS** and use it to communicate with the **SageMaker LLM inference endpoint** for handling real-time inference requests.

