SCHEME = $(HOME)/.local/bin/scheme
GHERKIN = $(or $(GHERKIN_DIR),$(HOME)/mine/gherkin/src)
LIBDIRS = src:$(GHERKIN)
COMPILE = $(SCHEME) -q --libdirs $(LIBDIRS) --compile-imported-libraries
COMPILE_ONE = $(COMPILE) --program compile-one.ss

O = src/gerbil-aws

ALL_SLS = \
  $O/aws-creds.sls \
  $O/aws-xml.sls \
  $O/aws-api.sls \
  $O/aws-json-api.sls \
  $O/ec2-params.sls \
  $O/ec2-params-test.sls \
  $O/ec2-xml.sls \
  $O/ec2-xml-test.sls \
  $O/ec2-api.sls \
  $O/ec2-instances.sls \
  $O/ec2-images.sls \
  $O/ec2-security-groups.sls \
  $O/ec2-key-pairs.sls \
  $O/ec2-vpcs.sls \
  $O/ec2-subnets.sls \
  $O/ec2-volumes.sls \
  $O/ec2-snapshots.sls \
  $O/ec2-addresses.sls \
  $O/ec2-network-interfaces.sls \
  $O/ec2-route-tables.sls \
  $O/ec2-internet-gateways.sls \
  $O/ec2-nat-gateways.sls \
  $O/ec2-tags.sls \
  $O/ec2-regions.sls \
  $O/ec2-launch-templates.sls \
  $O/s3-xml.sls \
  $O/s3-xml-test.sls \
  $O/s3-api.sls \
  $O/s3-buckets.sls \
  $O/s3-objects.sls \
  $O/sts-api.sls \
  $O/sts-operations.sls \
  $O/iam-api.sls \
  $O/iam-users.sls \
  $O/iam-groups.sls \
  $O/iam-roles.sls \
  $O/iam-policies.sls \
  $O/iam-access-keys.sls \
  $O/lambda-api.sls \
  $O/lambda-functions.sls \
  $O/logs-api.sls \
  $O/logs-operations.sls \
  $O/dynamodb-api.sls \
  $O/dynamodb-operations.sls \
  $O/sns-api.sls \
  $O/sns-operations.sls \
  $O/sqs-api.sls \
  $O/sqs-operations.sls \
  $O/cfn-api.sls \
  $O/cfn-stacks.sls \
  $O/cloudwatch-api.sls \
  $O/cloudwatch-operations.sls \
  $O/rds-api.sls \
  $O/rds-db-instances.sls \
  $O/elbv2-api.sls \
  $O/elbv2-operations.sls \
  $O/compute-optimizer-api.sls \
  $O/compute-optimizer-operations.sls \
  $O/cost-optimization-hub-api.sls \
  $O/cost-optimization-hub-operations.sls \
  $O/ssm-api.sls \
  $O/ssm-operations.sls \
  $O/ssm-session.sls \
  $O/cli-format.sls

.PHONY: all compile gherkin binary clean help run

all: gherkin compile

# Translate .ss -> .sls via gherkin compiler (use make -j8 gherkin)
gherkin: $(ALL_SLS)

# Compile .sls -> .so via Chez
compile: gherkin
	$(COMPILE) < build-all.ss

# Build = full pipeline
build: binary

# Native binary
binary: clean gherkin
	$(SCHEME) -q --libdirs $(LIBDIRS) --program build-binary.ss

# Run interpreted
run: all
	$(SCHEME) -q --libdirs $(LIBDIRS) --program aws.ss

clean:
	rm -f gerbil-aws-main.o gerbil_aws_program.h
	rm -f gerbil-aws.boot gerbil-aws-all.so aws.so aws.wpo
	rm -f petite.boot scheme.boot
	find src -name '*.so' -o -name '*.wpo' | xargs rm -f 2>/dev/null || true
	rm -f $(ALL_SLS)

help:
	@echo "Targets:"
	@echo "  all          - Translate .ss->.sls + compile .sls->.so"
	@echo "  build        - Build standalone binary (./gerbil-aws)"
	@echo "  binary       - Same as build"
	@echo "  run          - Run interpreted"
	@echo "  gherkin      - Translate .ss -> .sls (use -j8 for parallel)"
	@echo "  compile      - Compile .sls -> .so only"
	@echo "  clean        - Remove all build artifacts"
	@echo "  help         - Show this help"

# --- Per-module gherkin translation targets ---
$O/aws-creds.sls: compile-one.ss
	-@$(COMPILE_ONE) aws/creds.ss aws-creds

$O/aws-xml.sls: compile-one.ss
	-@$(COMPILE_ONE) aws/xml.ss aws-xml

# aws-api.sls is manually maintained (keyword dispatch, extra imports)
# $O/aws-api.sls: $O/aws-xml.sls $O/aws-creds.sls
# 	-@$(COMPILE_ONE) aws/api.ss aws-api

$O/aws-json-api.sls: $O/aws-creds.sls
	-@$(COMPILE_ONE) aws/json-api.ss aws-json-api

$O/ec2-params.sls: compile-one.ss
	-@$(COMPILE_ONE) ec2/params.ss ec2-params

$O/ec2-params-test.sls: $O/ec2-params.sls
	-@$(COMPILE_ONE) ec2/params-test.ss ec2-params-test

$O/ec2-xml.sls: compile-one.ss
	-@$(COMPILE_ONE) ec2/xml.ss ec2-xml

$O/ec2-xml-test.sls: $O/ec2-xml.sls
	-@$(COMPILE_ONE) ec2/xml-test.ss ec2-xml-test

$O/ec2-api.sls: $O/ec2-xml.sls $O/aws-creds.sls
	-@$(COMPILE_ONE) ec2/api.ss ec2-api

$O/ec2-instances.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/instances.ss ec2-instances

$O/ec2-images.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/images.ss ec2-images

$O/ec2-security-groups.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/security-groups.ss ec2-security-groups

$O/ec2-key-pairs.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/key-pairs.ss ec2-key-pairs

$O/ec2-vpcs.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/vpcs.ss ec2-vpcs

$O/ec2-subnets.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/subnets.ss ec2-subnets

$O/ec2-volumes.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/volumes.ss ec2-volumes

$O/ec2-snapshots.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/snapshots.ss ec2-snapshots

$O/ec2-addresses.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/addresses.ss ec2-addresses

$O/ec2-network-interfaces.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/network-interfaces.ss ec2-network-interfaces

$O/ec2-route-tables.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/route-tables.ss ec2-route-tables

$O/ec2-internet-gateways.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/internet-gateways.ss ec2-internet-gateways

$O/ec2-nat-gateways.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/nat-gateways.ss ec2-nat-gateways

$O/ec2-tags.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/tags.ss ec2-tags

$O/ec2-regions.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/regions.ss ec2-regions

$O/ec2-launch-templates.sls: $O/ec2-params.sls $O/ec2-api.sls
	-@$(COMPILE_ONE) ec2/launch-templates.ss ec2-launch-templates

$O/s3-xml.sls: compile-one.ss
	-@$(COMPILE_ONE) s3/xml.ss s3-xml

$O/s3-xml-test.sls: $O/s3-xml.sls
	-@$(COMPILE_ONE) s3/xml-test.ss s3-xml-test

$O/s3-api.sls: $O/s3-xml.sls $O/aws-creds.sls
	-@$(COMPILE_ONE) s3/api.ss s3-api

$O/s3-buckets.sls: $O/s3-api.sls
	-@$(COMPILE_ONE) s3/buckets.ss s3-buckets

$O/s3-objects.sls: $O/s3-api.sls
	-@$(COMPILE_ONE) s3/objects.ss s3-objects

$O/sts-api.sls: $O/aws-api.sls
	-@$(COMPILE_ONE) sts/api.ss sts-api

$O/sts-operations.sls: $O/sts-api.sls
	-@$(COMPILE_ONE) sts/operations.ss sts-operations

$O/iam-api.sls: $O/aws-api.sls
	-@$(COMPILE_ONE) iam/api.ss iam-api

$O/iam-users.sls: $O/iam-api.sls
	-@$(COMPILE_ONE) iam/users.ss iam-users

$O/iam-groups.sls: $O/iam-api.sls
	-@$(COMPILE_ONE) iam/groups.ss iam-groups

$O/iam-roles.sls: $O/iam-api.sls
	-@$(COMPILE_ONE) iam/roles.ss iam-roles

$O/iam-policies.sls: $O/iam-api.sls
	-@$(COMPILE_ONE) iam/policies.ss iam-policies

$O/iam-access-keys.sls: $O/iam-api.sls
	-@$(COMPILE_ONE) iam/access-keys.ss iam-access-keys

$O/lambda-api.sls: $O/aws-creds.sls
	-@$(COMPILE_ONE) lambda/api.ss lambda-api

$O/lambda-functions.sls: $O/lambda-api.sls
	-@$(COMPILE_ONE) lambda/functions.ss lambda-functions

$O/logs-api.sls: $O/aws-json-api.sls
	-@$(COMPILE_ONE) logs/api.ss logs-api

$O/logs-operations.sls: $O/logs-api.sls
	-@$(COMPILE_ONE) logs/operations.ss logs-operations

$O/dynamodb-api.sls: $O/aws-json-api.sls
	-@$(COMPILE_ONE) dynamodb/api.ss dynamodb-api

$O/dynamodb-operations.sls: $O/dynamodb-api.sls
	-@$(COMPILE_ONE) dynamodb/operations.ss dynamodb-operations

$O/sns-api.sls: $O/aws-api.sls
	-@$(COMPILE_ONE) sns/api.ss sns-api

$O/sns-operations.sls: $O/sns-api.sls
	-@$(COMPILE_ONE) sns/operations.ss sns-operations

$O/sqs-api.sls: $O/aws-json-api.sls
	-@$(COMPILE_ONE) sqs/api.ss sqs-api

$O/sqs-operations.sls: $O/sqs-api.sls
	-@$(COMPILE_ONE) sqs/operations.ss sqs-operations

$O/cfn-api.sls: $O/aws-api.sls
	-@$(COMPILE_ONE) cfn/api.ss cfn-api

$O/cfn-stacks.sls: $O/cfn-api.sls
	-@$(COMPILE_ONE) cfn/stacks.ss cfn-stacks

$O/cloudwatch-api.sls: $O/aws-api.sls
	-@$(COMPILE_ONE) cloudwatch/api.ss cloudwatch-api

$O/cloudwatch-operations.sls: $O/aws-xml.sls $O/cloudwatch-api.sls
	-@$(COMPILE_ONE) cloudwatch/operations.ss cloudwatch-operations

$O/rds-api.sls: $O/aws-api.sls
	-@$(COMPILE_ONE) rds/api.ss rds-api

$O/rds-db-instances.sls: $O/rds-api.sls
	-@$(COMPILE_ONE) rds/db-instances.ss rds-db-instances

$O/elbv2-api.sls: $O/aws-api.sls
	-@$(COMPILE_ONE) elbv2/api.ss elbv2-api

$O/elbv2-operations.sls: $O/elbv2-api.sls
	-@$(COMPILE_ONE) elbv2/operations.ss elbv2-operations

$O/compute-optimizer-api.sls: $O/aws-json-api.sls
	-@$(COMPILE_ONE) compute-optimizer/api.ss compute-optimizer-api

$O/compute-optimizer-operations.sls: $O/compute-optimizer-api.sls
	-@$(COMPILE_ONE) compute-optimizer/operations.ss compute-optimizer-operations

$O/cost-optimization-hub-api.sls: $O/aws-json-api.sls
	-@$(COMPILE_ONE) cost-optimization-hub/api.ss cost-optimization-hub-api

$O/cost-optimization-hub-operations.sls: $O/cost-optimization-hub-api.sls
	-@$(COMPILE_ONE) cost-optimization-hub/operations.ss cost-optimization-hub-operations

$O/ssm-api.sls: $O/aws-json-api.sls
	-@$(COMPILE_ONE) ssm/api.ss ssm-api

$O/ssm-operations.sls: $O/ssm-api.sls
	-@$(COMPILE_ONE) ssm/operations.ss ssm-operations

$O/ssm-session.sls: $O/ssm-operations.sls $O/ssm-api.sls
	-@$(COMPILE_ONE) ssm/session.ss ssm-session

$O/cli-format.sls: compile-one.ss
	-@$(COMPILE_ONE) cli/format.ss cli-format

