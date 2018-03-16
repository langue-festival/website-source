# directories
base_dir := $(CURDIR)
elm_dir := $(base_dir)/elm
pages_dir := $(base_dir)/pages
build_dir := $(base_dir)/build
deploy_dir := $(base_dir)/deploy
node_modules := $(base_dir)/node_modules
node_bin := $(node_modules)/.bin
# target
sass_target := $(build_dir)/compiled-style.css
elm_target := $(build_dir)/compiled-elm.js
inline_pages := $(build_dir)/compiled-pages.js
assets_hash_js := $(build_dir)/assets-hash.js
assets_hash_scss := $(build_dir)/assets-hash.scss
# node_modules executables
elm_make := $(node_bin)/elm-make
elm_analyse := $(node_bin)/elm-analyse
node_sass := $(node_bin)/node-sass
postcss := $(node_bin)/postcss
inliner := $(node_bin)/inliner
# pages
pages_name := $(basename $(notdir $(wildcard $(pages_dir)/*)))
pages := $(addsuffix .html, $(pages_name))

.PHONY: elm

all : deploy-files

yarn :
	@yarn

yarn-check :
ifeq ("$(wildcard $(node_bin))", "")
	@make yarn
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

deploy-env :
	@mkdir -p $(deploy_dir)

inliner : deploy-env yarn elm sass
	@rm -f $(pages_dir)/*.html
	@node $(base_dir)/make-inline-pages.js $(inline_pages)
	@$(postcss) $(sass_target) --use autoprefixer --replace
	@$(inliner) --inlinemin --noimages $(base_dir)/main.html > $(deploy_dir)/index.html
	@echo "Successfully generated $(deploy_dir)/index.html"

%.html :
	@cd $(deploy_dir) && ln -sf index.html $(notdir $@)

index.html :
	:

deploy-files : inliner
	@make $(pages)
	@cd $(deploy_dir) && ln -sf index.html 404.html
	@mkdir -p $(deploy_dir)/assets
	@rsync -r $(base_dir)/assets/fonts/. $(deploy_dir)/assets/fonts
	@rsync -r $(base_dir)/assets/images/. $(deploy_dir)/assets/images
	@rsync -r $(base_dir)/assets/pictures/. $(deploy_dir)/assets/pictures
	@rsync -r $(base_dir)/download/. $(deploy_dir)/download
	@echo "Successfully generated deploy files in $(deploy_dir)"

clean :
	@rm -rf $(base_dir)/yarn.lock $(elm_dir)/elm-stuff
	@rm -rf $(node_modules) $(build_dir)
	@rm -rf $(deploy_dir)
