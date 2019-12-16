component Preview {
  property size : Number = 500
  property url : String = ""

  state loaded : Bool = false

  style base {
    position: relative;
    background: white;
    user-select: none;
    overflow: hidden;
  }

  style iframe {
    transform-origin: 0 0;
    border: 0;

    transition: opacity 140ms;
    pointer-events: none;
    opacity: #{opacity};
    width: #{size}px;
  }

  get opacity : Number {
    if (loaded) {
      1
    } else {
      0
    }
  }

  fun update : Promise(Never, Void) {
    try {
      case (base) {
        Maybe::Just baseEl =>
          case (preview) {
            Maybe::Just previewEl =>
              try {
                rect =
                  Dom.getDimensions(baseEl)

                frame =
                  Dom.getDimensions(previewEl)

                width =
                  rect.width

                transform =
                  "scale(" + Number.toString(width / size) + ")"

                height =
                  Number.toString(size / width * 100) + "%"

                previewEl
                |> Dom.Extra.setStyle("transform", transform)
                |> Dom.Extra.setStyle("height", height)

                void
              }

            => void
          }

        => void
      }

      next {  }
    }
  }

  fun handleLoad (event : Html.Event) : Promise(Never, Void) {
    next { loaded = true }
  }

  fun render : Html {
    <div::base as base>
      <iframe::iframe as preview
        onLoad={handleLoad}
        scrolling="no"
        tabindex="-1"
        src={url}/>
    </div>
  }
}