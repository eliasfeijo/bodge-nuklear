(cl:defpackage :nuklear.example
  (:use :cl)
  (:export run))
(cl:in-package :nuklear.example)

(defvar *window-width* 800)
(defvar *window-height* 600)


(defclass nuklear-app (clutz:application)
  (nk-context
   (nk-renderer :initform nil)
   (pixel-ratio :initform 0f0)
   (level :initform :easy)
   (nvg-renderer :initform nil))
  (:default-initargs
   :opengl-version '(3 3)
   :window-title "Nuklear Example"
   :window-width *window-width*
   :window-height *window-height*))


(defmethod clutz:init ((this nuklear-app))
  (with-slots (nk-context nk-renderer nvg-renderer) this
    (setf nvg-renderer (nnk:make-renderer)
          nk-context (nk:make-context (nnk:renderer-font nvg-renderer))
          nk-renderer (nuklear.renderer:make-renderer nk-context))))


(defmethod clutz:destroy ((this nuklear-app))
  (with-slots (nk-context nk-renderer nvg-renderer) this
    (nuklear.renderer:destroy-renderer nk-renderer)
    (nnk:destroy-renderer nvg-renderer)
    (nk:destroy-context nk-context)))


(defun compose-nuklear (app)
  (with-slots (nk-context level) app
    (claw:c-with ((rect (:struct (%nk:rect))))
      (let ((val (%nk:begin nk-context "Demo" (%nk:rect rect 100f0 100f0 400f0 400f0)
                            (logior %nk:+window-border+ %nk:+window-movable+ %nk:+window-scalable+
                                    %nk:+window-minimizable+ %nk:+window-title+))))
        (unless (= val 0)
          (%nk:layout-row-static nk-context 30f0 80 1)
          (unless (= (%nk:button-label nk-context "button") 0)
            (format t "~&button pressed"))
          (%nk:layout-row-dynamic nk-context 30f0 2)
          (unless (= (%nk:option-label nk-context "easy" (if (eq level :easy) 1 0)) 0)
            (setf level :easy))
          (unless (= (%nk:option-label nk-context "hard" (if (eq level :hard) 1 0)) 0)
            (setf level :hard))))
      (%nk:end nk-context))))


(defun register-input (app)
  (with-slots (nk-context) app
    (%nk:input-begin nk-context)

    (let* ((cursor (clutz:cursor-position app))
           (cursor-x (floor (aref cursor 0)))
           (cursor-y (floor (aref cursor 1))))
      (%nk:input-button nk-context %nk:+button-left+ cursor-x cursor-y
                        (case (clutz:mouse-button-state app :left)
                          (:pressed %nk:+true+)
                          (:released %nk:+false+)))
      (%nk:input-motion nk-context cursor-x cursor-y))

    (%nk:input-end nk-context)))


(defmethod clutz:render ((this nuklear-app))
  (with-slots (nk-context nk-renderer nvg-renderer) this
    (gl:clear-color 0.5f0 0.5f0 0.5f0 1f0)
    (gl:clear :color-buffer-bit)

    (let ((renderer :nvg))
      (if (eq renderer :nvg)
          (%nk:style-set-font nk-context (claw:ptr (nnk:renderer-font nvg-renderer)))
          (claw:c-let ((atlas (:struct (%nk:font-atlas))
                              :from (nk.renderer::nk-renderer-font-atlas nk-renderer)))
            (%nk:style-set-font nk-context (atlas :default-font :handle))))

      (register-input this)
      (compose-nuklear this)

      (let* ((window-size (clutz:window-size this))
             (width (aref window-size 0))
             (height (aref window-size 1)))
        (if (eq renderer :nvg)
            (nnk:render-nuklear nvg-renderer nk-context width height)
            (nk.renderer:render-nuklear nk-renderer nk-context width height))))

    (%nk:clear nk-context)))


(defun run (&key (blocking t))
  (clutz:run (make-instance 'nuklear-app
                            :window-width *window-width*
                            :window-height *window-height*)
             :blocking blocking))
