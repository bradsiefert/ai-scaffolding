---
name: Migrate Nuxt 3.7 to 4.3 and Content v2 to v3
overview: Migrate from Nuxt 3.7 with @nuxt/content v2.7.2 to Nuxt 4.3 with @nuxt/content v3.11, including creating content collections, catch-all routes (documentDriven is removed), and updating all query APIs.
todos:
  - id: update-dependencies
    content: Update package.json with Nuxt 4.3 and @nuxt/content 3.11, then run npm install
    status: completed
  - id: create-content-config
    content: Create content.config.ts file with collections for blog, portfolio, case-studies, and siri-shortcuts, including Zod schemas for frontmatter
    status: completed
  - id: update-nuxt-config
    content: Remove documentDriven config (no longer supported), review markdown options for v3 compatibility
    status: completed
  - id: create-catchall-routes
    content: "Create catch-all route pages for: pages/blog/[...slug].vue, pages/portfolio/[...slug].vue, pages/siri-shortcuts/[...slug].vue (documentDriven is removed in v3)"
    status: completed
  - id: migrate-blog-page
    content: "Update pages/blog.vue: replace ContentList with useAsyncData + queryCollection, update _path to path, change sort to .order('date', 'DESC')"
    status: completed
  - id: migrate-portfolio-component
    content: "Update components/portfolio.vue: replace ContentList with useAsyncData + queryCollection, update _path to path"
    status: completed
  - id: migrate-portfolio-layout
    content: "Update layouts/portfolio-post.vue: replace queryContent().findOne() with queryCollection().path().first()"
    status: completed
  - id: handle-404
    content: Update or remove DocumentDrivenNotFound.vue (v2-specific), ensure error.vue handles 404s properly
    status: completed
  - id: test-content-rendering
    content: Test all content pages (blog, portfolio, siri-shortcuts), verify layouts apply, check draft filtering and date sorting
    status: completed
isProject: false
---

# Migration Plan: Nuxt 3.7 + Content v2 to Nuxt 4.3 + Content v3.11

## Overview

This plan migrates the bradsiefert.com site from Nuxt 3.7 with @nuxt/content v2.7.2 to Nuxt 4.3 with @nuxt/content v3.11. **Critical change:** `documentDriven` mode is removed in v3, requiring manual catch-all routes for content pages.

## Breaking Changes in Content v3

- `**documentDriven` mode removed** - Markdown files no longer auto-generate routes; must create catch-all pages manually
- `**queryContent()` → `queryCollection()**` - New SQL-backed API with different syntax
- `**ContentList` component removed** - Use `useAsyncData` + `queryCollection` + `v-for` instead
- `**_path` → `path**` - Property renamed (no underscore prefix)
- `**.findOne()` → `.first()**` and `**.find()` → `.all()**` - Method renames
- `**DocumentDrivenNotFound.vue**` - v2-specific component, won't work in v3

## Current State Analysis

- **Dependencies**: Nuxt 3.7.0, @nuxt/content 2.7.2
- **Content Structure**: 
  - `/content/blog/` - 14 blog posts
  - `/content/portfolio/` - 6 portfolio items (active)
  - `/content/case-studies/` - 1 active case study (others in Vue files)
  - `/content/siri-shortcuts/` - 12 shortcuts (no page exists, relies on documentDriven)
- **Content Usage**:
  - `queryContent()` in [layouts/portfolio-post.vue](layouts/portfolio-post.vue)
  - `ContentList` in [pages/blog.vue](pages/blog.vue) and [components/portfolio.vue](components/portfolio.vue)
  - `documentDriven: true` in [nuxt.config.ts](nuxt.config.ts)

## Migration Steps

### 1. Update Dependencies

Update [package.json](package.json):

```json
"devDependencies": {
  "@nuxt/content": "^3.11.0",
  "nuxt": "^4.3.0"
}
```

Run `npm install` to install new dependencies.

### 2. Create Content Collections Configuration

Create **NEW FILE** `content.config.ts` in project root:

```typescript
import { defineContentConfig, defineCollection } from '@nuxt/content'
import { z } from 'zod'

export default defineContentConfig({
  collections: {
    blog: defineCollection({
      type: 'page',
      source: 'blog/*.md',
      schema: z.object({
        title: z.string(),
        date: z.string(),
        description: z.string().optional(),
        tags: z.array(z.string()).optional(),
        draft: z.boolean().default(false),
        layout: z.string().optional(),
        category: z.string().optional(),
        'head.image': z.string().optional(),
        alt: z.string().optional()
      })
    }),
    portfolio: defineCollection({
      type: 'page',
      source: 'portfolio/*.md',
      schema: z.object({
        title: z.string(),
        date: z.string(),
        draft: z.boolean().default(false),
        layout: z.string().optional(),
        category: z.string().optional(),
        'head.image': z.string().optional()
      })
    }),
    'siri-shortcuts': defineCollection({
      type: 'page',
      source: 'siri-shortcuts/*.md',
      schema: z.object({
        title: z.string(),
        date: z.string().optional(),
        category: z.string().optional()
      })
    })
  }
})
```

### 3. Update Nuxt Configuration

Update [nuxt.config.ts](nuxt.config.ts):

- **Remove** `documentDriven: true` (not supported in v3)
- Keep `markdown.anchorLinks: false` if still needed

```typescript
export default defineNuxtConfig({
  // ... app config unchanged ...
  modules: ['@nuxt/content'],
  content: {
    // documentDriven removed - no longer supported
    markdown: {
      anchorLinks: false
    }
  },
  // ... css unchanged ...
})
```

### 4. Create Catch-All Routes (Critical)

Since `documentDriven` is removed, create catch-all routes for content:

**NEW FILE** `pages/blog/[...slug].vue`:

```vue
<script lang="ts" setup>
const route = useRoute()
const { data: page } = await useAsyncData(route.path, () => {
  return queryCollection('blog').path(route.path).first()
})

if (!page.value) {
  throw createError({ statusCode: 404, message: 'Page not found' })
}

// Apply layout from frontmatter
const layout = computed(() => page.value?.layout || 'blog-post')
</script>

<template>
  <NuxtLayout :name="layout">
    <ContentRenderer v-if="page" :value="page" />
  </NuxtLayout>
</template>
```

**NEW FILE** `pages/portfolio/[...slug].vue` (similar pattern)

**NEW FILE** `pages/siri-shortcuts/[...slug].vue` (similar pattern)

### 5. Migrate Blog Page

Update [pages/blog.vue](pages/blog.vue):

- Remove `QueryBuilderParams` import
- Replace `ContentList` with `useAsyncData` + `queryCollection`
- Change `blog._path` to `blog.path`

```vue
<script setup lang="ts">
// Remove: import type { QueryBuilderParams } from '@nuxt/content/dist/runtime/types'

const { data: blogPosts } = await useAsyncData('blog-list', () => {
  return queryCollection('blog')
    .where('draft', '=', false)
    .order('date', 'DESC')
    .all()
})

// ... rest of script unchanged ...
</script>

<template>
  <!-- Replace ContentList with v-for -->
  <div class="blog-card" v-for="blog in blogPosts" :key="blog.path">
    <NuxtLink :to="blog.path">
      <!-- ... existing content, change _path to path ... -->
    </NuxtLink>
  </div>
</template>
```

### 6. Migrate Portfolio Component

Update [components/portfolio.vue](components/portfolio.vue):

- Remove `QueryBuilderParams` import
- Replace `ContentList` with `useAsyncData` + `queryCollection`
- Change `portfolio._path` to `portfolio.path`

### 7. Migrate Portfolio Layout

Update [layouts/portfolio-post.vue](layouts/portfolio-post.vue):

```vue
<script setup>
const route = useRoute()

// Replace: queryContent(route.path).findOne()
const { data: document, error } = await useAsyncData('current-document', () => {
  return queryCollection('portfolio').path(route.path).first()
})

const pageTitle = computed(() => {
  if (error.value) return 'Portfolio Post'
  return document.value?.title || 'Portfolio Post'
})
</script>
```

### 8. Handle 404 Pages

- **Remove or update** `components/DocumentDrivenNotFound.vue` (v2-specific)
- Ensure [error.vue](error.vue) handles 404s properly (already exists)
- Add error handling in catch-all routes with `createError()`

### 9. Test Content Rendering

Verify:

- Blog list page loads and displays posts
- Individual blog posts render with `blog-post` layout
- Portfolio list page loads
- Individual portfolio items render with `portfolio-post` layout
- Siri shortcuts pages render (e.g., `/siri-shortcuts/01-days-old-and-days-left`)
- Draft filtering works
- Date sorting works correctly
- Images and markdown elements display properly

## Files Summary


| File                                    | Action                                         |
| --------------------------------------- | ---------------------------------------------- |
| `package.json`                          | Update dependency versions                     |
| `content.config.ts`                     | **NEW** - Collection definitions               |
| `nuxt.config.ts`                        | Remove `documentDriven`, update content config |
| `pages/blog/[...slug].vue`              | **NEW** - Catch-all route for blog posts       |
| `pages/portfolio/[...slug].vue`         | **NEW** - Catch-all route for portfolio items  |
| `pages/siri-shortcuts/[...slug].vue`    | **NEW** - Catch-all route for shortcuts        |
| `pages/blog.vue`                        | Replace `ContentList`, update queries          |
| `components/portfolio.vue`              | Replace `ContentList`, update queries          |
| `layouts/portfolio-post.vue`            | Update `queryContent` to `queryCollection`     |
| `components/DocumentDrivenNotFound.vue` | Remove or repurpose                            |


## Potential Issues & Solutions

### Path Format Changes

- v2 paths: `_path` with `/blog/01-initial-commit`
- v3 paths: `path` - verify format matches routes
- Solution: Test path matching, may need to normalize in queries

### Layout Selection

- v2 auto-applied layouts from frontmatter
- v3 requires manual layout selection in catch-all routes
- Solution: Read `layout` from content data, use `<NuxtLayout :name="layout">`

### Draft Filtering Syntax

- v2: `.where({ draft: { $ne: true } })`
- v3: `.where('draft', '=', false)` or `.where('draft', '!=', true)`
- Solution: Use SQL-like operators in v3

### Nested head.image Property

- Frontmatter uses `head.image` with dot notation
- May need to access as `head?.image` in templates
- Solution: Test property access, update templates if needed

