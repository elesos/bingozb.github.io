<div class="copyright" >
  {% set current = date(Date.now(), "YYYY") %}
  Copyright © {% if theme.since and theme.since != current %} {{ theme.since }} - {% endif %}
  <span itemprop="copyrightYear">{{ current }}
  </span>
  <span class="author" itemprop="copyrightHolder">{{ config.author }}
  </span>
  All rights reserved.
</div>

<div class="powered-by">
  Powered by <a class="theme-link" href="https://github.com/bingozb">Bingo zb</a>
</div>
