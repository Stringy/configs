PROJECT_NAME := {{PROJECT_NAME}}
space := $(subst ,, )
SAFE_NAME := $(subst $(space),_,$(PROJECT_NAME))
SHUNN_DIR := $(HOME)/.config/stringy/templates/pandoc-shunn

.PHONY: wordcount today outline find compile pdf epub manuscript help deps

deps: ## Install dependencies (pandoc, LaTeX)
	sudo dnf install -y pandoc texlive-latex texlive-collection-fontsrecommended

help: ## Show this help
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

wordcount: ## Word count per chapter and total
	@total=0; \
	for f in chapters/*.md; do \
		[ -f "$$f" ] || continue; \
		words=$$(wc -w < "$$f"); \
		total=$$((total + words)); \
		printf "  %-40s %s words\n" "$$(basename "$$f")" "$$words"; \
	done; \
	echo ""; \
	printf "  Total: %s words\n" "$$total"

today: ## Words written since last commit
	@added=$$(git diff HEAD -- chapters/ 2>/dev/null | grep '^+[^+]' | wc -w); \
	removed=$$(git diff HEAD -- chapters/ 2>/dev/null | grep '^-[^-]' | wc -w); \
	delta=$$((added - removed)); \
	total=0; \
	for f in chapters/*.md; do \
		[ -f "$$f" ] || continue; \
		words=$$(wc -w < "$$f"); \
		total=$$((total + words)); \
	done; \
	if [ $$delta -ge 0 ]; then \
		echo "  +$$delta words since last commit ($$total total)"; \
	else \
		echo "  $$delta words since last commit ($$total total)"; \
	fi

outline: ## First heading or first line of each chapter
	@for f in chapters/*.md; do \
		[ -f "$$f" ] || continue; \
		line=$$(grep -m1 '^#\|^[A-Z]' "$$f" 2>/dev/null || head -1 "$$f"); \
		printf "  %-20s %s\n" "$$(basename "$$f" .md)" "$$line"; \
	done

find: ## Search chapters for a term (usage: make find q="word")
	@grep -rn -i --color=always "$(q)" chapters/ || echo "  No matches for '$(q)'"

manuscript: ## Compile to Shunn manuscript format (DOCX)
	@mkdir -p build
	@$(SHUNN_DIR)/bin/md2long.sh \
		--output "build/$(SAFE_NAME)_manuscript.docx" \
		--overwrite \
		metadata.yaml chapters/*.md
	@echo "  build/$(SAFE_NAME)_manuscript.docx"

compile: pdf ## Alias for pdf

pdf: ## Compile to PDF via pandoc
	@mkdir -p build
	@pandoc chapters/*.md \
		--metadata title="$(PROJECT_NAME)" \
		--top-level-division=chapter \
		-o "build/$(SAFE_NAME).pdf"
	@echo "  build/$(SAFE_NAME).pdf"

epub: ## Compile to EPUB via pandoc
	@mkdir -p build
	@pandoc chapters/*.md \
		--metadata title="$(PROJECT_NAME)" \
		--top-level-division=chapter \
		-o "build/$(SAFE_NAME).epub"
	@echo "  build/$(SAFE_NAME).epub"
