<script lang="ts">
  interface Props {
    variant?: 'icon' | 'inline';
    size?: 'tiny' | 'small' | 'medium' | 'large' | 'giant';
    class?: string;
  }

  let { variant = 'icon', size = 'medium', class: className = '' }: Props = $props();

  const sizeMap = {
    tiny: 'h-6',
    small: 'h-8',
    medium: 'h-10',
    large: 'h-12',
    giant: 'h-24',
  };

  const heightClass = sizeMap[size];
</script>

{#if variant === 'inline'}
  <div class="flex items-center gap-2 {className}">
    <img src="/rpictures-logo.png" alt="rPictures" class={heightClass} />
    <span class="text-xl font-semibold text-primary">rPictures</span>
  </div>
{:else}
  <img src="/rpictures-logo.png" alt="rPictures" class="{heightClass} {className}" />
{/if}
