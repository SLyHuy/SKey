.DEFAULT_GOAL := help

SCHEME       := SKey
PROJECT      := SKey.xcodeproj
DERIVED_DATA := build/DerivedData
DEV_APP      := $(DERIVED_DATA)/Build/Products/Debug/SKey Dev.app
RELEASE_APP  := $(DERIVED_DATA)/Build/Products/Release/SKey.app
INSTALL_APP  := /Applications/SKey.app

.PHONY: help gen test build-dev run-dev stop-dev release install homebrew clean

help: ## Hiển thị danh sách các lệnh
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

gen: ## Tạo lại SKey.xcodeproj từ project.yml bằng XcodeGen
	xcodegen generate

test: ## Chạy toàn bộ unit test của SKeyEngine
	cd Packages/SKeyEngine && swift test

build-dev: ## Build bản Debug (SKey Dev.app)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-derivedDataPath $(DERIVED_DATA) build

run-dev: build-dev ## Build và chạy thử SKey Dev (tạm tắt bản release đang chạy)
	-pkill -x "SKey" 2>/dev/null || true
	-pkill -x "SKey Dev" 2>/dev/null || true
	open "$(DEV_APP)"

stop-dev: ## Tắt SKey Dev và mở lại /Applications/SKey.app
	-pkill -x "SKey Dev" 2>/dev/null || true
	@if [ -d "$(INSTALL_APP)" ]; then open "$(INSTALL_APP)"; fi

release: ## Build bản Release (universal, ký ad-hoc) và đóng gói DMG/zip trong dist/
	./scripts/release.sh

install: release ## Build bản Release và cài đè vào /Applications/SKey.app
	-pkill -x "SKey Dev" 2>/dev/null || true
	-pkill -x "SKey" 2>/dev/null || true
	rm -rf "$(INSTALL_APP)"
	ditto "$(RELEASE_APP)" "$(INSTALL_APP)"
	open "$(INSTALL_APP)"

homebrew: ## Đồng bộ SLyHuy/homebrew-tap với GitHub Release mới nhất
	./scripts/publish-homebrew.sh

clean: ## Xoá thư mục build/ và dist/
	rm -rf build dist

