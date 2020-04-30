#
# Constants
#
VERSION := 0.12.24
OS := linux
ARCH := amd64
ZIP := terraform_$(VERSION)_$(OS)_$(ARCH).zip
SUMS := terraform_$(VERSION)_SHA256SUMS
URL := https://releases.hashicorp.com/terraform/$(VERSION)
TF := distfiles/terraform-$(VERSION)

#
# Terraform source files
#
GENSRC := aws_regions.tf.json providers.tf.json peering.tf.json
TFSRC := $(shell find * -type f -a \( -name '*.tf' -o -name '*.tf.json' \) )
TFSRC := $(TFSRC) $(GENSRC)
PLANSRC := $(TFSRC) .terraform/modules/modules.json .terraform/plugins/$(OS)_$(ARCH)/lock.json

# release tarball sources
RELSRC := external hashicorp.asc main.tf Makefile modules README regiondb.json scripts terraform.tfvars.json variables.tf
RELSRC := $(shell find $(RELSRC) \! -type d)

#
# User entry points
#
all: plan
init: .stamps/init
plan: tfplan.json terraform.tfstate.json terraform.tfstate.backup.json
apply: .stamps/apply output.json
release: aws-global-net.tar.gz
fmt: $(TF) scripts/softlimit
	./scripts/softlimit $(TF) fmt -no-color -recursive -write=false -check -diff
.PHONY: all init plan apply release fmt

#
# Rules for downloading and verifying the terraform binary
#
distfiles/$(SUMS).sig:
	mkdir -p distfiles 
	curl -o "$@.tmp" "$(URL)/$(SUMS).sig"
	mv -f -- "$@.tmp" "$@"

distfiles/$(SUMS): distfiles/$(SUMS).sig hashicorp.asc
	curl -o "$@.tmp" "$(URL)/$(SUMS)"
	set -eux \
	  && tmp="$$(mktemp -d)" \
	  && trap 'rm -rf -- "$$tmp"' EXIT \
	  && gpg --homedir "$$tmp" --import hashicorp.asc \
	  && gpg --homedir "$$tmp" --trust-model always --verify "$<" "$@.tmp"
	  && exec rm -rf -- "$$tmp"
	mv -f -- "$@.tmp" "$@"

distfiles/$(SUMS)_$(OS)_$(ARCH): distfiles/$(SUMS)
	awk '$$2 == "$(ZIP)" { print $$1 "\tdistfiles/" $$2 ".tmp" }' < "$<" > "$@.tmp"
	mv -f -- "$@.tmp" "$@"

distfiles/$(ZIP): distfiles/$(SUMS)_$(OS)_$(ARCH)
	curl -o "$@.tmp" "$(URL)/$(ZIP)"
	sha256sum -c < "$<"
	mv -f -- "$@.tmp" "$@"

$(TF): distfiles/$(ZIP)
	cd distfiles && unzip "$(ZIP)"
	touch distfiles/terraform
	mv -f distfiles/terraform "$@"

#
# Rules for generating *.tf.json, using scripts/*
#
%.tf.json: scripts/% regiondb.json
	"$<" < regiondb.json > "$@.tmp"
	mv -f -- "$@.tmp" "$@"

#
# Rules for running terraform
#
.stamps/init: $(TFSRC) $(TF) scripts/softlimit
	./scripts/softlimit $(TF) init -no-color
	mkdir -p .stamps
	touch "$@"
.terraform/modules/modules.json: .stamps/init
.terraform/plugins/$(OS)_$(ARCH)/lock.json: .stamps/init

tfplan: $(PLANSRC) $(TF) scripts/softlimit
	./scripts/softlimit $(TF) plan -no-color -out "$@.tmp"
	mv -f -- "$@.tmp" "$@"
terraform.tfstate: tfplan
terraform.tfstate.backup: tfplan
.PRECIOUS: terraform.tfstate terraform.tfstate.backup

tfplan.json: tfplan $(TF) scripts/softlimit
	./scripts/softlimit $(TF) show -no-color -json "$<" | jq . > "$@.tmp"
	mv -f -- "$@.tmp" "$@"

terraform.tfstate.json: terraform.tfstate $(TF) scripts/softlimit
	./scripts/softlimit $(TF) show -no-color -json < "$<" | jq . > "$@.tmp"
	mv -f -- "$@.tmp" "$@"

terraform.tfstate.backup.json: terraform.tfstate.backup $(TF) scripts/softlimit
	./scripts/softlimit $(TF) show -no-color -json < "$<" | jq . > "$@.tmp"
	mv -f -- "$@.tmp" "$@"

.stamps/apply: tfplan $(TF) scripts/softlimit
	# https://github.com/hashicorp/terraform/issues/21330
	env AWS_DEFAULT_REGION=us-east-2 \
		./scripts/softlimit $(TF) apply -no-color "$<"
	touch "$@"

output.json: .stamps/apply $(TF) scripts/softlimit
	./scripts/softlimit $(TF) output -json > "$@.tmp"
	mv -f -- "$@.tmp" "$@"

aws-global-net.tar.gz: $(RELSRC)
	git archive --prefix aws-global-net/ HEAD -- $(RELSRC) | gzip -n9c > "$@.tmp"
	mv -f -- "$@.tmp" "$@"

#
# Clean
#
clean:
	-rm -rf .gnupg .stamps .terraform/modules
	-rm -f tfplan $(GENSRC) tfplan.json terraform.tfstate.json terraform.tfstate.backup.json aws-global-net.tar.gz output.json
	-find * -name '*.tmp' -exec rm -f -- {} +

distclean: clean
	-rm -rf distfiles .terraform

.PHONY: clean distclean
