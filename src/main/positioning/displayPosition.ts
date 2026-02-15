import { type Display, type Rectangle, screen } from "electron";

export function getTargetDisplay(): Display {
  const cursorPoint = screen.getCursorScreenPoint();
  return screen.getDisplayNearestPoint(cursorPoint);
}

export function getCenteredPrompterBounds(
  display: Display,
  size: Pick<Rectangle, "width" | "height">,
  topOffsetPx: number,
): Rectangle {
  const menuBarHeight = Math.max(0, display.workArea.y - display.bounds.y);
  const blendIntoMenuBarPx = Math.min(12, menuBarHeight);
  const anchoredY = display.bounds.y + Math.max(0, menuBarHeight - blendIntoMenuBarPx);

  const x = Math.round(display.bounds.x + (display.bounds.width - size.width) / 2);
  const y = Math.max(display.bounds.y, Math.round(anchoredY + topOffsetPx));

  return {
    x,
    y,
    width: size.width,
    height: size.height,
  };
}
