#!chezscheme
;; Build driver: imports all modules to trigger Chez compilation
;; Modules commented out need additional manual fixups
(import
  (gerbil-aws aws-creds)
  (gerbil-aws aws-xml)
  (gerbil-aws aws-api)
  (gerbil-aws aws-json-api)
  (gerbil-aws ec2-params)
  ;; (gerbil-aws ec2-params-test) ;; needs :std/test
  ;; (gerbil-aws ec2-xml)        ;; manually maintained
  ;; (gerbil-aws ec2-xml-test)   ;; needs :std/test
  ;; (gerbil-aws ec2-api)        ;; needs deferror/keyword-dispatch fixup
  ;; (gerbil-aws ec2-instances)
  ;; (gerbil-aws ec2-images)
  ;; (gerbil-aws ec2-security-groups)
  ;; (gerbil-aws ec2-key-pairs)
  ;; (gerbil-aws ec2-vpcs)
  ;; (gerbil-aws ec2-subnets)
  ;; (gerbil-aws ec2-volumes)
  ;; (gerbil-aws ec2-snapshots)
  ;; (gerbil-aws ec2-addresses)
  ;; (gerbil-aws ec2-network-interfaces)
  ;; (gerbil-aws ec2-route-tables)
  ;; (gerbil-aws ec2-internet-gateways)
  ;; (gerbil-aws ec2-nat-gateways)
  ;; (gerbil-aws ec2-tags)
  ;; (gerbil-aws ec2-regions)
  ;; (gerbil-aws ec2-launch-templates)
  (gerbil-aws s3-xml)
  ;; (gerbil-aws s3-xml-test)    ;; needs :std/test
  (gerbil-aws s3-api)
  (gerbil-aws s3-buckets)
  (gerbil-aws s3-objects)
  (gerbil-aws sts-api)
  ;; (gerbil-aws sts-operations) ;; keyword dispatch
  (gerbil-aws iam-api)
  (gerbil-aws iam-users)
  (gerbil-aws iam-groups)
  (gerbil-aws iam-roles)
  (gerbil-aws iam-policies)
  (gerbil-aws iam-access-keys)
  ;; (gerbil-aws lambda-api)     ;; needs deferror/keyword-dispatch fixup
  ;; (gerbil-aws lambda-functions)
  (gerbil-aws logs-api)
  (gerbil-aws logs-operations)
  (gerbil-aws dynamodb-api)
  ;; (gerbil-aws dynamodb-operations) ;; keyword dispatch
  (gerbil-aws sns-api)
  ;; (gerbil-aws sns-operations) ;; keyword dispatch
  (gerbil-aws sqs-api)
  (gerbil-aws sqs-operations)
  (gerbil-aws cfn-api)
  (gerbil-aws cfn-stacks)
  (gerbil-aws cloudwatch-api)
  ;; (gerbil-aws cloudwatch-operations) ;; keyword dispatch
  (gerbil-aws rds-api)
  (gerbil-aws rds-db-instances)
  (gerbil-aws elbv2-api)
  (gerbil-aws elbv2-operations)
  (gerbil-aws compute-optimizer-api)
  (gerbil-aws compute-optimizer-operations)
  (gerbil-aws cost-optimization-hub-api)
  (gerbil-aws cost-optimization-hub-operations)
  (gerbil-aws ssm-api)
  (gerbil-aws ssm-operations)
  ;; (gerbil-aws ssm-session)    ;; needs random-u8vector
  ;; (gerbil-aws cli-format)     ;; needs pretty-json
)
