declare const SRC: string

declare module "inline:*" {
  const content: string
  export default content
}

declare module "*.scss" {
  const content: string
  export default content
}

declare module "*.blp" {
  const content: string
  export default content
}

declare module "*.css" {
  const content: string
  export default content
}

declare module "gi://*" {
  const content: any
  export default content
}

declare module "lunar-javascript" {
  export const Solar: any;
  export const Lunar: any;
}
