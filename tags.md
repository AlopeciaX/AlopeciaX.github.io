---
layout: archive
title: Tags
permalink: /tags
---

{% for tag in site.tags %}
  <h3 id="{{ tag[0] }}">#{{ tag[0] }}</h3>
  <ul>
    {% for post in tag[1] %}
      <li>
        <span class="archive_date">{{ post.date | date: "%Y.%m.%d" }}</span>
        <a href="{{ post.url }}">{{ post.title }}</a>
      </li>
    {% endfor %}
  </ul>
{% endfor %}
