# directories
base_dir		:= $(CURDIR)
elm_dir			:= $(base_dir)/elm
build_dir		:= $(base_dir)/build
node_modules	:= $(base_dir)/node_modules
node_bin		:= $(node_modules)/.bin
# target
sass_target			:= $(build_dir)/compiled-style.css
elm_target			:= $(build_dir)/compiled-elm.js
inline_pages		:= $(build_dir)/compiled-pages.js
assets_hash_js		:= $(build_dir)/assets-hash.js
assets_hash_scss	:= $(build_dir)/assets-hash.scss
inliner_target		:= $(base_dir)/index.html
# node_modules executables
elm_make	:= $(node_bin)/elm-make
elm_analyse	:= $(node_bin)/elm-analyse
node_sass	:= $(node_bin)/node-sass
postcss		:= $(node_bin)/postcss
inliner		:= $(node_bin)/inliner

.PHONY: elm

all : inliner

yarn :
	@yarn

yarn-check :
ifeq ("$(wildcard $(node_bin))", "")
	make yarn
endif

build-env :
	@mkdir -p $(build_dir)/assets
	@ln -sf $(base_dir)/assets/fonts $(build_dir)/assets
	@node $(base_dir)/make-assets-hash.js $(assets_hash_js) $(assets_hash_scss)

elm : yarn-check build-env
	@cd $(elm_dir) && $(elm_make) src/App.elm --output=$(elm_target) --warn --yes

elm-analyse : elm
	@cd $(elm_dir) && $(elm_analyse)

sass : yarn-check build-env
	@$(node_sass) --output-style compressed assets/scss/main.scss > $(sass_target)
	@echo "Successfully generated $(sass_target)"

dev : elm sass
	@rm -f $(inline_pages)

inliner : yarn elm sass
	@node $(base_dir)/make-inline-pages.js $(inline_pages)
	@$(postcss) $(sass_target) --use autoprefixer --replace
	@$(inliner) --inlinemin --noimages $(base_dir)/main.html > $(inliner_target)
	@echo "Successfully generated $(inliner_target)"

clean :
	@rm -rf $(node_modules) $(build_dir) $(base_dir)/yarn.lock
	@rm -rf $(elm_dir)/elm-stuff
	@rm -f $(inliner_target)
