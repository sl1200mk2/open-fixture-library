# select all JSON files in schemas/ directory
schema-files := $(wildcard schemas/*.json)

# replace schemas/ with schemas/dereferenced/
dereferenced-schema-files := $(schema-files:schemas/%=schemas/dereferenced/%)



### PHONY rules, see https://stackoverflow.com/a/2145605/451391

.PHONY: all no-nuxt register plugin-data test-fixtures schemas model-docs nuxt-build clean

no-nuxt: register plugin-data test-fixtures schemas model-docs

only-gitignored-no-nuxt: register schemas

all: register plugin-data test-fixtures schemas model-docs nuxt-build

register: fixtures/register.json

plugin-data: plugins/plugins.json

test-fixtures: tests/test-fixtures.json tests/test-fixtures.md

schemas: $(dereferenced-schema-files)

model-docs: docs/model-api.md

nuxt-build:
	$$(npm bin)/nuxt build

clean:
	rm -rf schemas/dereferenced
	rm -rf .nuxt


### file rules

fixtures/register.json: \
fixtures/*/*.json \
fixtures/manufacturers.json \
cli/make-register.js
	node cli/make-register.js
	@echo ""

plugins/plugins.json: \
plugins/*/plugin.json \
plugins/*/*.js \
plugins/*/exportTests/*.js \
cli/make-plugin-data.js \
$(schema-files) # OFL plugin version depends on the schema
	node cli/make-plugin-data.js
	@echo ""

tests/test-fixtures.json: \
lib/fixture-features/*.js \
fixtures/register.json \
lib/model/*.mjs \
cli/make-test-fixtures.js \
$(dereferenced-schema-files)
	node cli/make-test-fixtures.js
	@echo ""

tests/test-fixtures.md: \
tests/test-fixtures.json

schemas/dereferenced/%.json: \
$(schema-files) \
cli/make-dereferenced-schemas.js
	@mkdir -p schemas/dereferenced
	node cli/make-dereferenced-schemas.js "$*.json"
	@echo ""


jsdoc2md := $(shell echo $$(npm bin)/jsdoc2md)
jsdoc2md-cmd := $(jsdoc2md) --configure jsdoc-config.json --private --files lib/model/*.mjs > docs/model-api.md

docs/model-api.md: \
lib/model/*.mjs \
jsdoc-config.json
	@test -f $(jsdoc2md) && (echo "$(jsdoc2md-cmd)" && $(jsdoc2md-cmd)) || echo "$(jsdoc2md) not available"
	@echo ""
