---
layout: page
title: About
description: 认真写代码，什么也不怕
keywords: Soveran Zhong, Yi Xiang Zhong, 钟翼翔, SRE, DevOps
comments: true
menu: 关于
permalink: /about/
---

我是钟翼翔，翅膀很硬，喜欢逆风飞翔。

码农这条路很难，但既然下定决心走下去，那就码上行动，不能嘴上逞强。


## 联系

<ul>
{% for website in site.data.social %}
<li>{{website.sitename }}：<a href="{{ website.url }}" target="_blank">@{{ website.name }}</a></li>
{% endfor %}
{% if site.url contains 'mazhuang.org' %}
<li>
<!--微信公众号：<br />
 <img style="height:192px;width:192px;border:1px solid lightgrey;" src="{{ site.url }}/assets/images/qrcode.jpg" alt="闷骚的程序员" /> -->
</li>
{% endif %}
</ul>


## Skill Keywords

{% for skill in site.data.skills %}
### {{ skill.name }}
<div class="btn-inline">
{% for keyword in skill.keywords %}
<button class="btn btn-outline" type="button">{{ keyword }}</button>
{% endfor %}
</div>
{% endfor %}
