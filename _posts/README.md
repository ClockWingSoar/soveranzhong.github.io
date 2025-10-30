# 文档索引

本仓库包含以下文档（点击打开）：

- [hexo-deployment-guide.md](hexo-deployment-guide.md)
- [http-protocol-guide.md](http-protocol-guide.md)
- [ip-subnetting-guide.md](ip-subnetting-guide.md)
- [linux-commands-guide.md](linux-commands-guide.md)
- [linux-file-metadata-guide.md](linux-file-metadata-guide.md)
- [linux-file-operations-guide.md](linux-file-operations-guide.md)
- [linux-filesystem-guide.md](linux-filesystem-guide.md)
- [nodejs-hexo-nginx-deployment-guide.md](nodejs-hexo-nginx-deployment-guide.md)
- [osi-model-guide.md](osi-model-guide.md)
- [shell-concepts-guide.md](shell-concepts-guide.md)
- [shell-guide.md](shell-guide.md)
- [subnetting-guide.md](subnetting-guide.md)
- [vmware-installation-guide.md](vmware-installation-guide.md)
- [vmware-installation-guide.assets/](vmware-installation-guide.assets/)

## 在 GitHub Pages 上发布

1. 将本文件 `README.md` 提交到仓库根目录。
2. 进入 仓库 Settings → Pages，选择分支（例如 `main` 或 `gh-pages`）并选择根目录（/）。
3. 若需保留静态资源目录，建议在仓库根目录添加 `.nojekyll` 文件，防止 Jekyll 处理资源。

示例命令：
```bash
git add README.md
touch .nojekyll
git add .nojekyll
git commit -m "Add README for GitHub Pages"
git push