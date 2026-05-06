# AWS Security Group Management with Ansible

This playbook allows you to modify the AWS security group created by Terraform to add additional ingress rules.

## Prerequisites

1. Install the Amazon AWS collection:
```bash
ansible-galaxy collection install amazon.aws
```

2. Install boto3 and botocore Python packages:
```bash
pip install boto3 botocore
```

3. Configure AWS credentials (one of the following):
   - AWS CLI configured: `aws configure`
   - Environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
   - IAM role (if running on EC2)

## Usage

### Add Port 3000 Ingress Rule

Run the playbook to add ingress rule for port 3000:

```bash
cd ansible
ansible-playbook update_security_group.yml
```

### Customize for Different Regions or Projects

You can override the default values using environment variables:

```bash
# For a different AWS region
export AWS_REGION=us-west-2
ansible-playbook update_security_group.yml

# For a different project name
export PROJECT_NAME=my-project
ansible-playbook update_security_group.yml

# Or pass as extra vars
ansible-playbook update_security_group.yml -e "aws_region=us-west-2" -e "project_name=my-project"
```

## What the Playbook Does

1. Looks up the security group by the tag `Name: <project_name>-sg`
2. Retrieves current security group configuration
3. Adds an ingress rule for TCP port 3000 from 0.0.0.0/0
4. Preserves all existing rules
5. Reports whether changes were made

## Modifying for Other Ports

To add different ports, edit the `update_security_group.yml` file and modify the `rules` section:

```yaml
rules:
  - proto: tcp
    from_port: 3000
    to_port: 3000
    cidr_ip: 0.0.0.0/0
    rule_desc: "Allow HTTP traffic on port 3000"
  - proto: tcp
    from_port: 8080
    to_port: 8080
    cidr_ip: 0.0.0.0/0
    rule_desc: "Allow HTTP traffic on port 8080"
```

## Security Considerations

- The playbook adds rules with `0.0.0.0/0` (open to all). For production, restrict to specific IP ranges:
  ```yaml
  cidr_ip: 10.0.0.0/8  # Internal network only
  ```

- Always review security group changes before applying
- Consider using AWS Security Group best practices
- Regularly audit security group rules

## Troubleshooting

### Error: Security group not found
- Verify the project name matches your Terraform deployment
- Check the AWS region is correct
- Ensure Terraform has created the infrastructure

### Error: Insufficient permissions
- Ensure your AWS credentials have `ec2:DescribeSecurityGroups` and `ec2:AuthorizeSecurityGroupIngress` permissions

### Error: Module not found
- Install the amazon.aws collection: `ansible-galaxy collection install amazon.aws`
- Install boto3: `pip install boto3 botocore`