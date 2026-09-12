# AWS Architecture Icons 2026

## Base icon style template

Every AWS icon should use this structure:

```text
sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;fillColor=<CATEGORY_COLOR>;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.<service_name>;
```

Critical properties:

- **strokeColor=#ffffff** for white icon lines
- **verticalLabelPosition=bottom** to prevent text overlap
- **fillColor** varies by service category

## Category color table

| Category                        | fillColor | Examples                                                |
| ------------------------------- | --------- | ------------------------------------------------------- |
| Compute                         | #ED7100   | Lambda, EC2, ECS, Fargate, Batch                        |
| Containers                      | #ED7100   | ECS, EKS, ECR                                           |
| Network & Content Delivery      | #8C4FFF   | CloudFront, VPC, Route 53, ELB, API Gateway             |
| Analytics                       | #8C4FFF   | Athena, Kinesis, Redshift, EMR, QuickSight              |
| Storage                         | #7AA116   | S3, EBS, EFS, Glacier, Storage Gateway                  |
| IoT                             | #7AA116   | IoT Core, Greengrass                                    |
| Database                        | #C925D1   | DynamoDB, RDS, Aurora, ElastiCache, Neptune             |
| Developer Tools                 | #C925D1   | CodeBuild, CodePipeline, CodeDeploy                     |
| Security, Identity & Compliance | #DD344C   | Cognito, IAM, WAF, Shield, KMS                          |
| Front-End Web & Mobile          | #DD344C   | Amplify                                                 |
| Application Integration         | #E7157B   | SQS, SNS, Step Functions, EventBridge                   |
| Management & Governance         | #E7157B   | CloudWatch, CloudFormation, CloudTrail, Systems Manager |
| AI/ML                           | #01A88D   | SageMaker, Bedrock, Rekognition, Comprehend             |
| Migration & Modernization       | #01A88D   | DMS, Migration Hub                                      |
| General Resources               | #1E262E   | Users, AWS Cloud, Internet, Generic resource            |

## AWS group containers

Base group style template:

```text
points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=<GROUP_ICON>;strokeColor=<STROKE_COLOR>;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#232F3E;dashed=0;
```

| Group Type        | grIcon                               | strokeColor |
| ----------------- | ------------------------------------ | ----------- |
| AWS Cloud         | mxgraph.aws4.group_aws_cloud_alt     | #232F3E     |
| Region            | mxgraph.aws4.group_region            | #00A4A6     |
| VPC               | mxgraph.aws4.group_vpc2              | #8C4FFF     |
| Public Subnet     | mxgraph.aws4.group_security_group    | #7AA116     |
| Private Subnet    | mxgraph.aws4.group_security_group    | #147EBA     |
| Availability Zone | mxgraph.aws4.group_availability_zone | #232F3E     |

Child elements reference groups via `parent="<group_id>"` attribute with relative positioning.

---

Based on [Agents365-ai/drawio-skill](https://github.com/Agents365-ai/drawio-skill) (MIT License).
AWS section based on [DevelopersIO](https://dev.classmethod.jp/articles/claude-code-trying-out-drawio-skill-for-aws-architecture/).
