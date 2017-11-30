# directories and elm target file
base_dir		:= $(CURDIR)
elm_dir			:= $(base_dir)/elm
build_dir		:= $(base_dir)/build
elm_target		:= $(build_dir)/compiled_elm.js
node_modules	:= $(base_dir)/node_modules
# executables in node_modules
elm_make	:= $(node_modules)/.bin/elm-make
elm_analyse	:= $(node_modules)/.bin/elm-analyse
inliner		:= $(node_modules)/.bin/inliner

.PHONY: elm

all : inliner

yarn :
	@yarn

elm-dev :
ifeq ("$(wildcard $(elm_make))", "")
	make yarn
	make elm
else
	@cd $(elm_dir) && $(elm_make) src/App.elm --output=$(elm_target) --warn --yes
endif

elm : elm-dev
	@cd $(elm_dir) && $(elm_analyse)

inliner : yarn elm
	@chmod a+x $(base_dir)/embed_pages.sh
	@$(base_dir)/embed_pages.sh
	@$(inliner) --inlinemin --noimages $(base_dir)/main.html > $(base_dir)/index.html

clean :
	@rm -rf $(node_modules) $(base_dir)/yarn.lock
	@rm -rf $(build_dir) $(elm_dir)/elm-stuff
	@rm -f index.html
