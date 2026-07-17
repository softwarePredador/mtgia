export const dynamic = "force-static";

export function GET() {
  return new Response("ok\n", {
    status: 200,
    headers: {
      "Cache-Control": "no-cache, no-store, must-revalidate",
      "Content-Type": "text/plain; charset=utf-8"
    }
  });
}
