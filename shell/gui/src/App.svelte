<script lang="ts">
  import Greet from './lib/Greet.svelte'
  import DownloadList from './lib/DownloadList.svelte'
  import SideMenu from './lib/SideMenu.svelte'
</script>

<main class="flex-1 flex">
  <aside class="w-1/4 border-solid border-r-2 border-indigo-600">
    <SideMenu/>
  </aside>

  <section class="flex-1">
    <DownloadList/>
  </section>
</main>

<style>
</style>
