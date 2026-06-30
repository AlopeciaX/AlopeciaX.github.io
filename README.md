# AlopeciaX's Blog

정보보안과 클라우드 인프라를 공부하며 기록하는 기술 블로그입니다.

Blog: https://alopeciax.github.io/aboutme.html

주요 카테고리
- security — 모의침투, 취약점 진단, 방화벽 실습
- cloud — Azure, Terraform 인프라 구축
- server — 서버 구축 및 운영 실습
- network — 네트워크 구성 및 보안 실습
- project — Azure 인프라 & Hybrid Cloud 보안 구축 프로젝트
- qualifications — 정보처리기사, 네트워크관리사 등 자격증 정리

---

# Catbook (Modified by AlopeciaX)
CATbook is a CATegory-centric Jekyll theme for bloggers. There is a switch button to toggle between dark mode and light mode. This theme is originally inspired from [Book](https://github.com/kkninjae/book) and modified by [AlopeciaX](https://github.com/AlopeciaX).

[![LICENSE](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) ![GENERATOR](https://img.shields.io/badge/made_with-jekyll-blue.svg) ![VERSION](https://img.shields.io/badge/current_version-1.0-green.svg)

**Demo:** https://starry99.github.io/catbook/
**My Blog:** [AlopeciaX's Blog](https://alopeciax.github.io)

![SCREENSHOT](https://starry99.github.io/catbook/assets/img/lmode.jpg)
![SCREENSHOT](https://starry99.github.io/catbook/assets/img/dmode.jpg)

## Setup

```sh
$ git clone https://github.com/starry99/catbook
$ jekyll serve

# Now you can start customization!
```

## Make it yours

If you want to create a new category, you need to create `*name*.html` in the `categories` folder. And add the following content:
```html
---
layout: page
type: *name*
---

{% include archive.html %}
```
Then the number of pages in the category will be displayed.

## License

This project is based on the [Catbook](https://github.com/starry99/catbook) theme, originally created by Starry99 and licensed under the MIT License.  
The modifications and additional content by [AlopeciaX](https://github.com/AlopeciaX) are also licensed under the [MIT License](./LICENSE).  
