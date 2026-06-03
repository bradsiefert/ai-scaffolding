# Vue 2 to Nuxt 4 + @nuxt/content 3 Migration Guide

## Overview

This guide covers migrating a Vue.js 2 application to the latest Nuxt (4.x) with @nuxt/content (3.x). The migration involves significant API changes, especially for content management.

---

## Phase 1: Project Setup

### 1.1 Update Dependencies

Replace your existing Vue 2 dependencies with Nuxt 4:

```json
{
  "devDependencies": {
    "@nuxt/content": "^3.11.0",
    "nuxt": "^4.3.0"
  },
  "dependencies": {
    "better-sqlite3": "^12.6.2"
  }
}
```

**Key notes:**
- `better-sqlite3` is required for @nuxt/content 3.x (it uses SQLite for content indexing)
- Remove Vue 2 specific packages (`vue`, `vue-router`, `vue-template-compiler`, etc.)
- Nuxt 4 includes Vue 3 automatically

### 1.2 Create/Update Config Files

**nuxt.config.ts:**
```typescript
export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      charset: 'utf-8',
      viewport: 'width=device-width, initial-scale=1',
    },
    pageTransition: {
      name: 'fade',
      mode: 'default',
      duration: 200
    }
  },
  modules: ['@nuxt/content'],
  content: {
    // documentDriven is REMOVED in v3 - use catch-all routes instead
    markdown: {
      anchorLinks: false
    }
  },
  css: ['@/assets/scss/styles.scss']
})
```

**content.config.ts** (NEW - required for @nuxt/content 3.x):
```typescript
import { defineCollection, defineContentConfig, z } from '@nuxt/content'

export default defineContentConfig({
  collections: {
    blog: defineCollection({
      type: 'page',
      source: 'blog/**/*.md',
      schema: z.object({
        title: z.string(),
        date: z.string(),
        description: z.string().optional(),
        draft: z.boolean().default(false),
        tags: z.array(z.string()).optional(),
        layout: z.string().optional(),
      })
    }),
    portfolio: defineCollection({
      type: 'page',
      source: 'portfolio/**/*.md',
      schema: z.object({
        title: z.string(),
        date: z.string(),
        draft: z.boolean().default(false),
        layout: z.string().optional(),
      })
    }),
    // Add more collections as needed
  }
})
```

---

## Phase 2: Directory Structure Changes

### 2.1 Nuxt Directory Structure

```
project/
├── app.vue                 # Root component (replaces main App.vue)
├── error.vue               # Custom error page
├── content.config.ts       # Content collections config (NEW)
├── nuxt.config.ts
├── assets/
│   └── scss/
├── components/
├── content/                # Markdown content files
│   ├── blog/
│   └── portfolio/
├── layouts/                # Page layouts
│   ├── default.vue
│   └── blog-post.vue
├── pages/                  # File-based routing
│   ├── index.vue
│   ├── blog/
│   │   ├── index.vue
│   │   └── [...slug].vue   # Catch-all for dynamic routes
│   └── portfolio/
│       ├── index.vue
│       └── [...slug].vue
└── public/                 # Static assets (replaces /static)
```

### 2.2 Key Structural Changes

| Vue 2 / Nuxt 2 | Nuxt 4 |
|----------------|--------|
| `src/App.vue` | `app.vue` |
| `src/views/` | `pages/` |
| `static/` | `public/` |
| `router/index.js` | File-based routing (automatic) |
| N/A | `content.config.ts` (required) |

---

## Phase 3: Content Query API Migration

### 3.1 Query Method Changes

**Old (@nuxt/content v2):**
```javascript
const { data } = await useAsyncData('posts', () =>
  queryContent('blog')
    .where({ draft: { $ne: true } })
    .sort({ date: -1 })
    .find()
)
```

**New (@nuxt/content v3):**
```javascript
const { data } = await useAsyncData('posts', () =>
  queryCollection('blog')
    .where('draft', '=', false)
    .order('date', 'DESC')
    .all()
)
```

### 3.2 API Changes Reference

| v2 Method | v3 Method |
|-----------|-----------|
| `queryContent('path')` | `queryCollection('collectionName')` |
| `.find()` | `.all()` |
| `.findOne()` | `.first()` |
| `.sort({ field: -1 })` | `.order('field', 'DESC')` |
| `.sort({ field: 1 })` | `.order('field', 'ASC')` |
| `.where({ draft: { $ne: true } })` | `.where('draft', '=', false)` |
| `_path` (in results) | `path` |
| `_id` | `id` |

### 3.3 Remove Deprecated Imports

```javascript
// REMOVE - no longer exists in v3
import type { QueryBuilderParams } from '@nuxt/content/dist/runtime/types'
```

---

## Phase 4: Create Catch-All Routes

Since `documentDriven` mode is removed, create catch-all routes for content pages.

**pages/blog/[...slug].vue:**
```vue
<script setup lang="ts">
const route = useRoute()
const slug = Array.isArray(route.params.slug)
  ? route.params.slug.join('/')
  : route.params.slug

const { data: post } = await useAsyncData(`blog-${slug}`, () =>
  queryCollection('blog').path(`/blog/${slug}`).first()
)

if (!post.value) {
  throw createError({ statusCode: 404, message: 'Post not found' })
}
</script>

<template>
  <ContentRenderer v-if="post" :value="post" />
</template>
```

---

## Phase 5: App Shell and Layouts

### 5.1 app.vue Setup

**Critical:** Wrap `<NuxtPage>` with `<NuxtLayout>` or layouts won't render:

```vue
<template>
  <header>
    <NavBar />
  </header>

  <main>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </main>

  <FooterComponent />
</template>

<script setup lang="ts">
useHead({
  titleTemplate: (title) => title ? `${title} | Site Name` : 'Site Name'
})
</script>
```

### 5.2 Layout Files

Layouts in `layouts/` are applied via frontmatter `layout: 'layout-name'` or `definePageMeta()`:

```vue
<!-- layouts/blog-post.vue -->
<template>
  <article class="blog-post">
    <slot />
  </article>
</template>
```

---

## Phase 6: Error Page Setup

### 6.1 error.vue Requirements

The error page must:
1. Define the `error` prop with `NuxtError` type
2. Use `clearError()` to navigate away
3. Include header/footer manually (it's outside the normal app shell)
4. Use public paths for images (not `@/assets` aliases)

```vue
<template>
  <header>
    <NavBar />
  </header>

  <main>
    <div class="container">
      <h1>{{ error?.statusCode === 404 ? 'Page Not Found' : 'Error' }}</h1>
      <p>{{ error?.message }}</p>
      <a href="/" @click.prevent="handleGoHome">Go Home</a>
    </div>
  </main>

  <FooterComponent />
</template>

<script setup lang="ts">
import type { NuxtError } from '#app'

defineProps<{
  error: NuxtError | null
}>()

function handleGoHome() {
  clearError({ redirect: '/' })
}

useHead({ title: 'Error' })
</script>
```

---

## Phase 7: Vue 3 Syntax Changes

### 7.1 Composition API

Vue 3 uses Composition API by default:

```vue
<!-- Old (Options API) -->
<script>
export default {
  data() {
    return { count: 0 }
  },
  methods: {
    increment() { this.count++ }
  }
}
</script>

<!-- New (Composition API) -->
<script setup>
const count = ref(0)
const increment = () => count.value++
</script>
```

### 7.2 Other Vue 3 Changes

- `v-model` on components uses `modelValue` prop
- `$listeners` removed (merged into `$attrs`)
- `::v-deep` → `:deep()`
- Filters removed (use computed properties or methods)
- `$set` / `$delete` removed (reactivity is automatic)

---

## Phase 8: Content Frontmatter

### 8.1 Draft Handling

Use `draft: true` in frontmatter for unpublished content:

```yaml
---
title: "My Draft Post"
date: 2024-01-15
draft: true
layout: blog-post
---
```

Filter in queries:
```javascript
queryCollection('blog').where('draft', '=', false).all()
```

### 8.2 Layout Assignment

Specify layout in frontmatter:
```yaml
---
layout: blog-post
---
```

---

## Migration Checklist

- [ ] Update `package.json` dependencies
- [ ] Install `better-sqlite3` for content module
- [ ] Create `nuxt.config.ts`
- [ ] Create `content.config.ts` with collections and Zod schemas
- [ ] Remove `documentDriven` config (not supported in v3)
- [ ] Restructure directories (`pages/`, `public/`, etc.)
- [ ] Create `app.vue` with `<NuxtLayout>` wrapping `<NuxtPage>`
- [ ] Create catch-all routes (`[...slug].vue`) for each content type
- [ ] Migrate all `queryContent()` → `queryCollection()` calls
- [ ] Update query methods (`.find()` → `.all()`, `.findOne()` → `.first()`)
- [ ] Update sort syntax (`.sort()` → `.order()`)
- [ ] Update where clauses to new syntax
- [ ] Change `_path` references to `path` in templates
- [ ] Remove `QueryBuilderParams` type imports
- [ ] Create `error.vue` with proper `error` prop and `clearError()`
- [ ] Update frontmatter to use `draft: true` for unpublished content
- [ ] Convert Options API to Composition API (`<script setup>`)
- [ ] Move static files from `static/` to `public/`
- [ ] Test all content pages render correctly
- [ ] Test 404/error pages work
- [ ] Test draft filtering works
- [ ] Verify layouts apply to content pages

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "NuxtLayout not used" warning | Wrap `<NuxtPage>` with `<NuxtLayout>` in `app.vue` |
| "An error has occurred" on 404 | Add `error` prop to `error.vue`, use public image paths |
| Content not rendering | Check `content.config.ts` collection `source` paths |
| Layouts not applying | Ensure frontmatter has `layout:` field matching layout filename |
| SQLite errors | Install `better-sqlite3` as a dependency |
| Queries return empty | Collection names in queries must match `content.config.ts` |

---

This plan should cover the major migration steps. Each project may have additional specifics depending on plugins, custom integrations, or unique content structures.
