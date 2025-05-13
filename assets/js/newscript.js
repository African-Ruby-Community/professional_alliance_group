(function ($) {
  "use strict";

  $(document).ready(function () {
    // Cache selectors
    var $pastEvents = $("#past-events");
    var $preloader = $(".preloader");
    var $preloaderNew = $(".preloader-new");
    var $mainHeader = $(".main-header");
    var $scrollLink = $(".scroll-to-top");
    var $mobileMenu = $(".mobile-menu");
    var $scheduleBlock = $(".schedule-block");
    var $dateBtn = $(".date-btn");
    var $bannerCarousel = $(".banner-carousel");
    var $singleItemCarousel = $(".single-item-carousel");
    var $tabsBox = $(".tabs-box");
    var $lightboxImage = $(".lightbox-image");
    var $scrollToTarget = $(".scroll-to-target");
    var $wowElements = $(".wow");

    // Add year selector
    $pastEvents.change(function () {
      var year = $(this).val();
      window.location.href = year === "main" ? `/` : `/${year}`;
    });

    function handlePreloader() {
      if ($preloader.length) {
        $preloader.fadeIn(200).delay(2000).fadeOut(200);
      } else if ($preloaderNew.length) {
        $preloaderNew.fadeIn(200);
        $(window).on("load", function () {
          $preloaderNew.fadeOut(200);
        });
      }
    }

    function headerStyle() {
      if ($mainHeader.length) {
        var windowpos = $(window).scrollTop();
        if (windowpos >= 1) {
          $mainHeader.addClass("fixed-header");
          $scrollLink.fadeIn(300);
        } else {
          $mainHeader.removeClass("fixed-header");
          $scrollLink.fadeOut(300);
        }
      }
    }

    headerStyle();

    if ($(".main-header li.dropdown ul").length) {
      $(".main-header .navigation li.dropdown").append(
        '<div class="dropdown-btn"><span class="fa fa-angle-down"></span></div>',
      );
    }

    if ($mobileMenu.length) {
      var mobileMenuContent = $(
        ".main-header .nav-outer .main-menu .navigation",
      ).html();
      $mobileMenu
        .append(
          '<div class="close-btn"><span class="icon flaticon-cancel-music"></span></div>',
        )
        .find(".navigation")
        .append(mobileMenuContent);
      $(".sticky-header .navigation").append(mobileMenuContent);

      $mobileMenu
        .on("click", ".close-btn", function () {
          $("body").removeClass("mobile-menu-visible");
        })
        .on("click", "li.dropdown .dropdown-btn", function () {
          $(this).prev("ul").slideToggle(500);
        })
        .on("click", ".menu-backdrop, .close-btn", function () {
          $("body").removeClass("mobile-menu-visible");
        });

      $(".mobile-nav-toggler").on("click", function () {
        $("body").addClass("mobile-menu-visible");
      });
    }

    if ($scheduleBlock.length) {
      $scheduleBlock.filter(".active").find(".lower-content").slideDown();
      $scheduleBlock.on("click", ".toggle-btn", function () {
        var $thisBlock = $(this).parents(".schedule-block");
        $thisBlock
          .toggleClass("active")
          .find(".lower-content")
          .slideToggle(400);
        $thisBlock
          .siblings()
          .removeClass("active")
          .find(".lower-content")
          .slideUp(400);
      });
    }

    if ($dateBtn.length) {
      var last_date = $dateBtn.attr("data-last-date");
      $dateBtn.on("click", function () {
        $(this).html(last_date);
      });
    }

    if ($bannerCarousel.length) {
      $bannerCarousel.owlCarousel({
        animateOut: "fadeOut",
        animateIn: "fadeIn",
        loop: true,
        margin: 0,
        nav: true,
        smartSpeed: 500,
        autoHeight: true,
        autoplay: true,
        autoplayTimeout: 5000,
        navText: [
          '<span class="fa fa-angle-left">',
          '<span class="fa fa-angle-right">',
        ],
        responsive: {
          0: { items: 1 },
          600: { items: 1 },
          1024: { items: 1 },
        },
      });
    }

    if ($singleItemCarousel.length) {
      $singleItemCarousel.owlCarousel({
        loop: true,
        margin: 0,
        nav: true,
        smartSpeed: 500,
        autoplay: true,
        navText: [
          '<span class="arrow_carrot-left"></span>',
          '<span class="arrow_carrot-right"></span>',
        ],
        responsive: {
          0: { items: 1 },
          600: { items: 1 },
          1024: { items: 1 },
        },
      });
    }

    function enableParallax() {
      for (var i = 1; i <= 5; i++) {
        var $scene = $(".parallax-scene-" + i);
        if ($scene.length) {
          new Parallax($scene.get(0));
        }
      }
    }

    enableParallax();

    function enableMasonry() {
      if ($(".masonry-items-container").length) {
        var $container = $(".masonry-items-container");
        $container.isotope({
          itemSelector: ".masonry-item",
          masonry: { columnWidth: 1 },
          animationOptions: { duration: 500, easing: "linear" },
        });

        $(window).on("resize", function () {
          $container.isotope({
            itemSelector: ".masonry-item",
            animationOptions: { duration: 500, easing: "linear", queue: false },
          });
        });
      }
    }

    enableMasonry();

    if ($tabsBox.length) {
      const savedTab = localStorage.getItem("activeTab");
      if (savedTab && $(savedTab).length) {
        const target = $(savedTab);
        $(".tabs-box .tab-buttons .tab-btn").removeClass("active-btn");
        $(".tabs-box .tabs-content .tab")
          .hide()
          .removeClass("active-tab animated fadeIn");
        target
          .parents(".tabs-box")
          .find(`.tab-buttons [data-tab="${savedTab}"]`)
          .addClass("active-btn");
        target.show().addClass("active-tab animated fadeIn");
      } else {
        $(".tabs-box .tab-buttons .tab-btn:first").addClass("active-btn");
        $(".tabs-box .tabs-content .tab:first")
          .show()
          .addClass("active-tab animated fadeIn");
      }

      $tabsBox.on("click", ".tab-buttons .tab-btn", function (e) {
        e.preventDefault();
        const target = $($(this).attr("data-tab"));
        if (!$(target).is(":visible")) {
          $(".tabs-box .tab-buttons .tab-btn").removeClass("active-btn");
          $(".tabs-box .tabs-content .tab")
            .fadeOut(0)
            .removeClass("active-tab animated fadeIn");
          $(this).addClass("active-btn");
          $(target).fadeIn(300).addClass("active-tab animated fadeIn");
          localStorage.setItem("activeTab", `#${target.attr("id")}`);
        }
      });
    }

    if ($lightboxImage.length) {
      $lightboxImage.fancybox({
        openEffect: "fade",
        closeEffect: "fade",
        helpers: { media: {} },
      });
    }

    if ($scrollToTarget.length) {
      $scrollToTarget.on("click", function () {
        var target = $(this).attr("data-target");
        $("html, body").animate({ scrollTop: $(target).offset().top }, 1500);
      });
    }

    if ($wowElements.length) {
      new WOW({
        boxClass: "wow",
        animateClass: "animated",
        offset: 0,
        mobile: true,
        live: true,
      }).init();
    }

    $(window).on("scroll", function () {
      headerStyle();
    });

    $(window).on("load", function () {
      handlePreloader();
      enableMasonry();
    });
  });
})(window.jQuery);
