# directories
base_dir		:= $(CURDIR)
elm_dir			:= $(base_dir)/elm
node_modules	:= $(base_dir)/node_modules
# target
sass_target		:= $(base_dir)/compiled_style.css
elm_target		:= $(base_dir)/compiled_elm.js
inline_pages	:= $(base_dir)/compiled_pages.js
inliner_target	:= $(base_dir)/index.html
# node_modules executables
bin			:= $(node_modules)/.bin
elm_make	:= $(bin)/elm-make
elm_analyse	:= $(bin)/elm-analyse
node_sass	:= $(bin)/node-sass
postcss		:= $(bin)/postcss
inliner		:= $(bin)/inliner

.PHONY: elm

all : inliner

yarn :
	@yarn

elm :
ifeq ("$(wildcard $(elm_make))", "")
	make yarn
	make elm
else
	@cd $(elm_dir) && $(elm_make) src/App.elm --output=$(elm_target) --warn --yes
endif

elm-analyse : elm
	@cd $(elm_dir) && $(elm_analyse)

sass :
ifeq ("$(wildcard $(node_sass))", "")
	make yarn
	make sass
else
	@$(node_sass) --output-style compressed main.scss > $(sass_target)
endif

dev : elm sass
	@rm -f $(inline_pages)

inliner : yarn elm sass
	@chmod a+x $(base_dir)/inline_pages.sh
	@$(base_dir)/inline_pages.sh $(inline_pages)
	@$(postcss) $(sass_target) --use autoprefixer --replace
	@$(inliner) --inlinemin --noimages $(base_dir)/main.html > $(inliner_target)

clean :
	@rm -rf $(node_modules) $(base_dir)/yarn.lock
	@rm -rf $(elm_dir)/elm-stuff
	@rm -f $(sass_target) $(elm_target)
	@rm -f $(inline_pages) $(inliner_target)
