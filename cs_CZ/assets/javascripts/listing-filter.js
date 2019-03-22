function listingFilter(opts) {
  "use strict"

  function doesSupportsModernWeb() {
    var array = []
    var string = ""
    var element = document.createElement("SPAN")

    try { return (
      typeof array.forEach === "function" &&
      typeof array.map === "function" &&
      typeof array.reduce === "function" &&
      typeof array.every === "function" &&
      typeof Object.keys === "function" &&
      typeof Object.create === "function" &&
      typeof string.trim === "function" &&
      "onpopstate" in window &&
      typeof window.history.pushState === "function" &&
      typeof JSON === "object" &&
      typeof JSON.parse === "function" &&
      typeof element.classList.add === "function" &&
      typeof element.classList.remove === "function"
    ) } catch (_) { return false }
  }

  function toArray(indexable) {
    return Array.prototype.slice.call(indexable, 0)
  }

  function sort(col) {
    var criteria = arguments.length === 1 ?
      [['asc', function(val) { return val }]] :
      toArray(arguments).slice(1)

    var collator = typeof Intl !== "undefined" ?
      new Intl.Collator(document.documentElement.lang) :
      null

    var compare = collator ?
      { target: collator,
        action: collator.compare } :
      { target: null,
        action: function(a, b) {
          if (a < b) return -1
          if (a > b) return +1
          return 0
        } }

    return toArray(col).sort(function(a, b) {
      var res = 0
      var i, order, byValue, valA, valB, isNum
      for (i = 0; i < criteria.length; i += 1) {
        switch (criteria[i][0]) {
        case 'asc':
          order = +1
          break
        case 'desc':
          order = -1
          break
        default:
          throw "Unexpected sort order criteria (" + criteria[i][0] + ")"
        }

        byValue = criteria[i][1]
        valA = byValue(a)
        valB = byValue(b)
        isNum = typeof valA === "number" && typeof valB === "number"
        res = order * (
          isNum ?
            valA - valB :
            compare.action.call(compare.target, valA, valB)
        )

        if (res !== 0) return res
      }

      return res
    })
  }

  function paramsFromHash(hash) {
    return !hash || hash === "#!" ? {} : hash.
      slice(1).
      split("&").
      map(function(rawPair) { return rawPair.split("=", 2) }).
      reduce(function(params, pair) {
        if (!params.hasOwnProperty(pair[0])) params[pair[0]] = []

        params[pair[0]].push(pair.length === 2 ? pair[1] : true)

        return params
      }, {})
  }

  function paramToString(key, vals) {
    return vals.map(function(val) {
      switch (typeof val) {
      case "string":
        return key + "=" + val
      case "boolean":
        return val ? key : ""
      default:
        throw "Unexpected type param val (" + (typeof val) + ") during " +
              "serialization"
      }
    }).join("&")
  }

  function paramsToHash(params) {
    return Object.keys(params).reduce(function(hash, key) {
      return hash + (hash ? "&" : "#") + paramToString(key, params[key])
    }, "")
  }

  function copyParams(params) {
    return Object.keys(params).reduce(function(cpy, key) {
      cpy[key] = [].concat(params[key])
      return cpy
    }, {})
  }

  function markFilters(params) {
    var optionsEls = document.getElementById("aside-right").
      getElementsByTagName("UL")

    if (optionsEls.length !== opts.types.length) {
      throw "Unexpected number of filter option lists " +
            "(" + optionsEls.length + ") " +
            "instead of " + opts.types.length + " " +
            "during filter marking based on filter parameters"
    }

    opts.types.forEach(function(typeOpts, i) {
      var optionsEl = optionsEls[i]
      toArray(optionsEl.getElementsByClassName("js-filter")).
        forEach(function(optionAnchorEl) {
          if (optionAnchorEl.getAttribute("data-filter-type") !== typeOpts.id) {
            throw "Unexpected filter type " +
                  "(" + optionAnchorEl.getAttribute("data-filter-type") + ") " +
                  "instead of '" + typeOpts.id + "'"
          }

          var optionEl = optionAnchorEl.parentNode
          var isActive = params.hasOwnProperty(typeOpts.id) &&
            params[typeOpts.id].indexOf(
              optionAnchorEl.getAttribute("data-filter-val")
            ) >= 0
          if (isActive) optionEl.classList.add("active")
          else optionEl.classList.remove("active")
        })
    })
  }

  function updateFilterLinks(params) {
    toArray(document.getElementsByClassName("js-filter")).
      forEach(function(el) {
        var typeId = el.getAttribute("data-filter-type")
        var valId = el.getAttribute("data-filter-val")

        var isToggle = JSON.parse(el.getAttribute("data-filter-toggle"))
        var isActive = params.hasOwnProperty(typeId) &&
          params[typeId].indexOf(valId) >= 0

        var localParams = copyParams(params)
        if (!localParams.hasOwnProperty(typeId)) localParams[typeId] = []
        if (isToggle && isActive) {
          localParams[typeId] = localParams[typeId].filter(function(param) {
            return valId !== param
          })
        } else if (!isActive) {
          localParams[typeId].push(valId)
        }

        Object.keys(localParams).forEach(function(typeId) {
          if (localParams[typeId].length <= 0) delete localParams[typeId]
        })

        el.href = Object.keys(localParams).length > 0 ?
          paramsToHash(localParams) :
          "#!"
      })
  }

  function applyFilters(params) {
    toArray(opts.filterable).forEach(function(el) {
      el.hidden = Object.keys(params).length > 0 ?
        !opts.types.every(function(typeOpts) {
          return params.hasOwnProperty(typeOpts.id) ?
            typeOpts.match(el, params[typeOpts.id]) :
            true
        }) :
        false
    })
  }

  function resetFilter() {
    toArray(opts.filterable).forEach(function(el) { el.hidden = false })
  }

  function filter(ev) {
    var params = paramsFromHash(ev.target.location.hash)
    markFilters(params)
    updateFilterLinks(params)
    applyFilters(params)
  }

  function findAvailableFilterValues(typeOpts) {
    return toArray(opts.filterable).
      map(function(el) { return typeOpts.values(el) }).
      reduce(function(flat, vals) { return flat.concat(vals) }, []).
      reduce(function(uniq, val) {
        if (uniq.ids.hasOwnProperty(val.id)) return uniq

        uniq.res.push(val)
        uniq.ids[val.id] = true
        return uniq
      }, { ids: {}, res: [] }).
      res
  }

  function createFilter(typeOpts) {
    var optionEls = sort.apply(
      null,
      [findAvailableFilterValues(typeOpts)].concat(typeOpts.sort)
    ).map(function(val) {
      var optionAnchorEl = document.createElement("A")
      optionAnchorEl.classList.add("js-filter")
      optionAnchorEl.setAttribute("data-filter-type", typeOpts.id)
      optionAnchorEl.setAttribute("data-filter-val", val.id)
      optionAnchorEl.setAttribute("data-filter-toggle", true)
      optionAnchorEl.textContent = val.hasOwnProperty("title") ?
        val.title :
        val.id

      var optionEl = document.createElement("LI")
      optionEl.appendChild(optionAnchorEl)

      return optionEl
    })
    if (typeOpts.order === 'desc') optionEls.reverse()

    var optionsEl = optionEls.reduce(function(optionsEl, optionEl) {
      optionsEl.appendChild(optionEl)
      return optionsEl
    }, document.createElement("UL"))

    if (optionsEl.childNodes.length <= 0) return null

    optionsEl.classList.add("filter-module")

    var headingEl = document.createElement("H3")
    headingEl.classList.add("moduleTitle")
    headingEl.textContent = typeOpts.title

    var divEl = document.createElement("DIV")
    divEl.classList.add("moduletable")
    divEl.appendChild(headingEl)
    divEl.appendChild(optionsEl)

    return divEl
  }

  function initNotSupported() {
    var asideParentEl = document.getElementById("aside-right")
    if (!asideParentEl) return
    var asideEl = asideParentEl.getElementsByTagName("ASIDE")[0]
    if (!asideEl) return

    var msg = document.createElement("P")
    msg.textContent = opts.notSupported

    asideEl.appendChild(msg)
  }

  function init(ev) {
    if (!doesSupportsModernWeb()) {
      initNotSupported()
      return
    }

    var asideParentEl = document.getElementById("aside-right")
    if (!asideParentEl) return
    var asideEl = asideParentEl.getElementsByTagName("ASIDE")[0]
    if (!asideEl) return

    opts.types.
      map(function(typeOpts) { return createFilter(typeOpts) }).
      filter(function(el) { return el }).
      reverse().
      forEach(function(el) { asideEl.insertBefore(el, asideEl.firstChild) })

    filter(ev)
  }

  window.addEventListener("popstate", filter, false)
  window.addEventListener("load", init, false)
  document.addEventListener("DOMContentLoaded", function(ev) {
    window.removeEventListener("load", init, false)
    init(ev)
  }, false)
}
