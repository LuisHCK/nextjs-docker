FROM node:18-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /home/nextjs/app
COPY package.json .
COPY yarn*.lock .
RUN --mount=type=cache,target=/root/.yarn YARN_CACHE_FOLDER=/root/.yarn yarn install --frozen-lockfile

FROM node:18-alpine AS builder
WORKDIR /home/nextjs/app
COPY --from=deps /home/nextjs/app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED 1
RUN yarn build

FROM node:18-alpine AS runner
WORKDIR /home/nextjs/app

ENV APP_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /home/nextjs/app/next.config.js ./next.config.js
COPY --from=builder /home/nextjs/app/public ./public
COPY --from=builder /home/nextjs/app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /home/nextjs/app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /home/nextjs/app/.next/static ./.next/
COPY --from=builder /home/nextjs/app/.env ./.env

USER nextjs
EXPOSE 8080
ENV PORT 8080

CMD ["node", "server.js"]