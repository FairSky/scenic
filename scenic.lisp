
(in-package :scenic)

(defparameter *width* 800)
(defparameter *height* 600)

(defun pixels-of (surface)
  (cffi:foreign-slot-value (slot-value surface 'sdl::foreign-pointer-to-object)
                           'sdl-cffi::Sdl-Surface
                           'sdl-cffi::pixels))

(defun pitch-of (surface)
  (cffi:foreign-slot-value (slot-value surface 'sdl::foreign-pointer-to-object)
                           'sdl-cffi::Sdl-Surface
                           'sdl-cffi::pitch))

(defun cairo-test ()
  (let* ((sdl-surf (sdl:create-surface 200 100))
         (surf (cl-cairo2:create-image-surface-for-data (pixels-of sdl-surf)
                                                        :argb32
                                                        200
                                                        100
                                                        (pitch-of sdl-surf)))
         (cl-cairo2:*context* (cl-cairo2:create-context surf)))
    (cl-cairo2:destroy surf)
    (cl-cairo2:set-source-rgb 0.2 0.2 1)
    (cl-cairo2:paint)
    (cl-cairo2:move-to 200 0)
    (cl-cairo2:line-to 0 100)
    (cl-cairo2:move-to 0 0)
    (cl-cairo2:line-to 200 100)
    (cl-cairo2:set-source-rgb 1 0.3 0.3)
    (cl-cairo2:set-line-width 10)
    (cl-cairo2:stroke)
    (cl-cairo2:destroy cl-cairo2:*context*)
    sdl-surf))

(defun render-scene (scene)
  (declare (ignore scene))
  (format t "hello~%")
  (sdl:clear-display (sdl:color :r 200 :g 200 :b 200))
  (sdl:blit-surface (cairo-test))
  (sdl-gfx:draw-box (sdl:rectangle :x 100 :y 100 :w 256 :h 192)
                    :color sdl:*blue*)
  (sdl-gfx:draw-box (sdl:rectangle :x 150 :y 170 :w 200 :h 100)
                    :color sdl:*red*)
  (sdl-gfx:draw-filled-pie-* 100 100 5 -180 0 :color sdl:*blue*)
  (sdl-gfx:draw-filled-circle-* 50 50 5 :color sdl:*red*)
  (sdl-gfx:draw-aa-circle-* 50 50 5 :color sdl:*red*)
  (sdl-gfx:draw-bezier (list (sdl:point :x 60  :y 40)
                             (sdl:point :x 160 :y 10)
                             (sdl:point :x 170 :y 150)
                             (sdl:point :x 60 :y 150))
                       :color sdl:*black*)
  ;; (break)
  ;; (sdl-gfx:roto-zoom-xy 0 0.5 0.5 t :surface sdl:*default-surface*)
  (sdl:update-display))

(defun run-scene (scene)
  (sdl:with-init ()
    (sdl:window *width* *height*)
    (setf (sdl:frame-rate) 60)
    (render-scene scene)
    (cairo-test)
    (sdl:with-events ()
      (:quit-event () t)
      (:key-down-event (:key key)
                       (when (sdl:key= key :sdl-key-escape)
                         (sdl:push-quit-event)))
      ;; (:idle (render-scene scene))
      (:video-expose-event () (sdl:update-display)))))