<script lang="ts">
  import type { HTMLImgAttributes } from 'svelte/elements';

  interface Props extends HTMLImgAttributes {
    noText?: boolean;
    class?: string | undefined;
  }

  let { noText = false, class: cssClass }: Props = $props();
</script>

<div class="flex items-center gap-3 {cssClass}">
  <img src="/rpictures-logo.png" alt="rPictures" class="h-full object-contain" />
  {#if !noText}
    <span class="text-xl font-semibold text-primary dark:text-immich-dark-primary">rPictures</span>
  {/if}
</div>
