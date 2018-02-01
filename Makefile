# directories
base_dir		:= $(CURDIR)
elm_dir			:= $(base_dir)/elm
build_dir		:= $(base_dir)/build
node_modules	:= $(base_dir)/node_modules
node_bin		:= $(node_modules)/.bin
# target
sass_target		:= $(build_dir)/compiled_style.css
elm_target		:= $(build_dir)/compiled_elm.js
inline_pages	:= $(build_dir)/compiled_pages.js
inliner_target	:= $(base_dir)/index.html
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

build-env :
	@mkdir -p $(build_dir)/assets
	@ln -s $(base_dir)/assets/fonts $(build_dir)/assets

check-yarn :
ifeq ("$(wildcard $(node_bin))", "")
	make yarn
endif

elm : build-env check-yarn
	@cd $(elm_dir) && $(elm_make) src/App.elm --output=$(elm_target) --warn --yes

elm-analyse : elm
	@cd $(elm_dir) && $(elm_analyse)

sass : build-env check-yarn
	@$(node_sass) --output-style compressed assets/scss/main.scss > $(sass_target)

dev : elm sass
	@rm -f $(inline_pages)

inliner : yarn elm sass
	@chmod a+x $(base_dir)/inline_pages.sh
	@$(base_dir)/inline_pages.sh $(inline_pages)
	@$(postcss) $(sass_target) --use autoprefixer --replace
	@$(inliner) --inlinemin --noimages $(base_dir)/main.html > $(inliner_target)

clean :
	@rm -rf $(node_modules) $(build_dir) $(base_dir)/yarn.lock
	@rm -rf $(elm_dir)/elm-stuff
	@rm -f $(inliner_target)
