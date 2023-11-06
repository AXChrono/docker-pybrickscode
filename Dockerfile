# Arguments
ARG NODE_TAG=12.18.3
ARG PYBRICKSCODE_TAG=v1.0.0-beta.14

# Build stage
FROM node:${NODE_TAG} AS build-stage
ARG PYBRICKSCODE_TAG
WORKDIR /app
RUN git clone https://github.com/pybricks/pybricks-code -b "${PYBRICKSCODE_TAG}" /app
RUN cd /app
RUN yarn install
RUN yarn build

# Production stage
FROM nginx:stable-alpine-slim
COPY --from=build-stage /app/build /usr/share/nginx/html
