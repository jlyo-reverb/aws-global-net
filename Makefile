VERSION := 0.12.0
OS := linux
ARCH := amd64
ZIP := terraform_$(VERSION)_$(OS)_$(ARCH).zip
SUMS := terraform_$(VERSION)_SHA256SUMS
URL := https://releases.hashicorp.com/terraform/$(VERSION)
TF := distfiles/terraform-$(VERSION)

GENSRC := aws_regions.tf.json providers.tf.json 
TFSRC := $(shell find * -type f -a \! -path '*/.terraform/*' -a \( -name '*.tf' -o -name '*.tf.json' \) )
TFSRC := $(TFSRC) $(GENSRC)

all: plan
init: .stamps/init
plan: tfplan
apply: .stamps/apply
fmt:
	$(TF) fmt
.PHONY: all init plan apply fmt

distfiles/$(SUMS).sig:
	mkdir -p distfiles 
	curl -o "$@.tmp" "$(URL)/$(SUMS).sig"
	mv -f -- "$@.tmp" "$@"

distfiles/$(SUMS): distfiles/$(SUMS).sig hashicorp.asc
	curl -o "$@.tmp" "$(URL)/$(SUMS)"
	gpg --homedir .gnupg --import hashicorp.asc
	gpg --homedir .gnupg --trust-model always --verify "$<" "$@.tmp"
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

providers.tf.json: regiondb.json scripts/providers
	scripts/providers < "$<" > "$@.tmp"
	mv -f -- "$@.tmp" "$@"

aws_regions.tf.json: regiondb.json scripts/aws_regions
	scripts/aws_regions < "$<" > "$@.tmp"
	mv -f -- "$@.tmp" "$@"

.stamps/init: $(TF) $(TFSRC)
	$(TF) init
	mkdir -p .stamps && touch "$@"

tfplan: .stamps/init $(TF)
	$(TF) plan -out "$@.tmp"
	mv -f -- "$@.tmp" "$@"

.stamps/apply: tfplan $(TF)
	$(TF) apply "$<"
	touch "$@"

clean:
	-rm -rf .gnupg .stamps
	-rm -f tfplan $(GENSRC)
.PHONY: clean
