---
layout: page
title: Tags
permalink: /tags
---

<script>
function filterTag(tagName) {
  document.querySelectorAll('.tag_section').forEach(el => {
    el.style.display = 'none';
  });
  document.getElementById(tagName).style.display = 'block';
  
  document.querySelectorAll('.tag_btn').forEach(el => {
    el.style.opacity = '0.5';
  });
  event.target.style.opacity = '1';
}

function showAll() {
  document.querySelectorAll('.tag_section').forEach(el => {
    el.style.display = 'block';
  });
  document.querySelectorAll('.tag_btn').forEach(el => {
    el.style.opacity = '1';
  });
}
</script>

<div style="margin-bottom: 1.5rem;">
  <a href="#" class="tag_btn" onclick="showAll()" style="color: var(--nav_font); margin-right: 8px;">전체</a>
  {% for tag in site.tags %}
    <a href="#" class="tag_btn" onclick="filterTag('{{ tag[0] }}')" style="color: var(--nav_font); margin-right: 8px;">#{{ tag[0] }}</a>
  {% endfor %}
</div>

{% for tag in site.tags %}
<div class="tag_section" id="{{ tag[0] }}">
  <h3>#{{ tag[0] }}</h3>
  <ul>
    {% for post in tag[1] %}
      <li>
        <span class="archive_date">{{ post.date | date: "%Y.%m.%d" }}</span>
        <a href="{{ post.url }}">{{ post.title }}</a>
      </li>
    {% endfor %}
  </ul>
</div>
{% endfor %}
