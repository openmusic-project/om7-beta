;============================================================================
; om#: visual programming language for computer-assisted music composition
;============================================================================
;
;   This program is free software. For information on usage
;   and redistribution, see the "LICENSE" file in this distribution.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;
;============================================================================
; File author: J. Bresson
;============================================================================

;=========================================================================
; Managing inouts and outputs in patches
;=========================================================================

(in-package :om)


;;;==========================
;;; IN/OUT BOXES
;;;==========================

(defclass OMPatchIO (OMPatchComponent)
  ((doc :initform "" :accessor doc :initarg :doc)
   (index :initform nil :accessor index)))

(defclass OMIn (OMPatchIO)
  ((defval :initform nil :accessor defval :initarg :defval)
   (in-symbol :initform nil :accessor in-symbol))
  (:documentation "An input of the current patch."))

(defclass OMOut (OMPatchIO) ()
  (:documentation "An output of the current patch."))

(defmethod get-inputs ((self OMPatch))
  (sort (remove
         nil
         (loop for box in (boxes self)
               when (equal (type-of (reference box)) 'OMIn)
               ;; here we do not include the special inputs (thisbox, thissequencer etc.)
               collect (reference box)))
        '< :key #'(lambda (i) (or (index i) 0))))

(defmethod get-outputs ((self OMPatch))
  (sort (remove
         nil
         (loop for box in (boxes self)
               when (subtypep (type-of (reference box)) 'OMOut)
               collect (reference box)))
        '< :key #'(lambda (o) (or (index o) 0))))


(defmethod omNG-make-new-boxcall ((reference OMPatchIO) pos &optional init-args)
  (let* ((box (make-instance (get-box-class reference)
                             :name (name reference)
                             :reference reference
                             :icon-pos :top
                             :text-align :center
                             :color (make-color-or-nil :color (om-def-color :transparent)
                                                       :t-or-nil t)
                             :border 0))
         (size (minimum-size box)))
    (setf (box-x box) (om-point-x pos)
          (box-y box) (om-point-y pos)
          (box-w box) (om-point-x size)
          (box-h box) (om-point-y size))
    box))



;;;==========================
;;; BOX
;;;==========================

;;; GENERAL SUPERCLASS
(defclass OMInOutBox (OMPatchComponentBox) ())

;;; other OMPatchComponentBox just save their box-symbol
(defmethod save-box-reference ((self OMInOutBox))
  (omng-save (reference self)))


(defmethod h-resizable ((self OMInOutBox)) nil)

(defmethod io-box-icon-color ((self t)) (om-def-color :black))

(defmethod related-patchbox-slot ((self OMInOutBox)) nil)

(defmethod set-name ((self OMInOutBox) name)
  (setf (name (reference self)) name)
  (when (and (container self)
             (related-patchbox-slot self))
    (loop for ref in (box-references-to (container self))
          do
          (setf (name
                 (nth (1- (index (reference self)))
                      (funcall (related-patchbox-slot self) ref))
                 ) name)))
  (call-next-method))

(defmethod allow-text-input ((self OMInOutBox))
  (values
   (name self)
   #'(lambda (box text) (set-name box text))))

(defmethod box-draw ((self OMInOutBox) frame)
  (let* ((size (om-make-point 20 16))
         (pos (if (equal (box-draw-icon-pos self) :left)
                  (om-make-point 0 (- (h frame) 24))
                (om-make-point (round (- (w frame) (om-point-x size)) 2) 8))))

    (om-with-fg-color (io-box-icon-color self)
      (om-draw-rect (+ (om-point-x pos) 3) (om-point-y pos)
                    (- (om-point-x size) 6) (- (om-point-y size) 6)
                    :fill t)
      (om-draw-polygon (list (om-point-x pos) (+ (om-point-y pos) (- (om-point-y size) 8))
                             (+ (om-point-x pos) (om-point-x size)) (+ (om-point-y pos) (- (om-point-y size) 8))
                             (+ (om-point-x pos) (/ (om-point-x size) 2)) (+ (om-point-y pos) (om-point-y size)))
                       :fill t)
      )

    (om-with-fg-color (om-def-color :white)
      (om-with-font (om-def-font :normal-b)
                    (om-draw-string (- (+ (om-point-x pos) (/ (om-point-x size) 2)) 4)
                                    (if (equal (box-draw-icon-pos self) :left) 14 18)
                                    (number-to-string (index (reference self))))
                    ))
    t))



;;;====================================
;; SPECIFIC BOXES
;;;====================================

;;;====================================
;;; IN (GENERAL)
(defclass OMInBox (OMInOutBox) ())
(defmethod box-n-outs ((self OMInBox)) 1)
(defmethod io-box-icon-color ((self OMInBox)) (om-make-color 0.2 0.6 0.2))

(defmethod special-box-p ((name (eql 'in))) t)
(defmethod get-box-class ((self OMIn)) 'OMInBox)
(defmethod related-patchbox-slot ((self OMInBox)) 'inputs)
(defmethod box-symbol ((self OMIn)) 'in)
(defmethod special-item-reference-class ((item (eql 'in))) 'OMIn)


(defmethod next-optional-input ((self OMInBox))
  (not (inputs self)))

(defmethod more-optional-input ((self OMInBox) &key name (value nil val-supplied-p) doc reactive)
  (declare (ignore name doc))
  (unless (inputs self)
    (add-optional-input self :name "internal input value"
                        :value (if val-supplied-p value nil)
                        :doc "set box value"
                        :reactive reactive)
    t))

(defmethod omNG-make-special-box ((reference (eql 'in)) pos &optional init-args)
  (let ((name (car (list! init-args)))
        (val (cadr (list! init-args))))
    (let ((box (omNG-make-new-boxcall
                (make-instance 'OMIn :name (if name (string name) "in")) ; :defval val
                pos init-args)))
      (when val
        (add-optional-input box :name "internal input value"
                            :value val
                            :doc "set box value"))
      box)))

(defmethod current-box-value ((self OMInBox) &optional (numout nil))
  (if numout (return-value self numout) (value self)))

;;;===================================
;;; OUT
(defclass OMOutBox (OMInOutBox) ())
(defmethod box-n-outs ((self OMOutBox)) 0)
(defmethod io-box-icon-color ((self OMOutBox)) (om-make-color 0.3 0.6 0.8))

(defmethod create-box-inputs ((self OMOutBox))
  (list
   (make-instance 'box-input
                  :name "out-value"
                  :box self
                  :value NIL
                  :doc-string "Connect here")))

(defmethod special-box-p ((name (eql 'out))) t)
(defmethod get-box-class ((self OMOut)) 'OMOutBox)
(defmethod related-patchbox-slot ((self OMOutBox)) 'outputs)
(defmethod box-symbol ((self OMOut)) 'out)
(defmethod special-item-reference-class ((item (eql 'out))) 'OMOut)


(defmethod omNG-make-special-box ((reference (eql 'out)) pos &optional init-args)
  (let ((name (car (list! init-args))))
    (omNG-make-new-boxcall
     (make-instance 'OMOut :name (if name (string name) "out"))
     pos init-args)))

;;;====================================
;; PATCH INTEGRATION
;;;====================================

(defmethod register-patch-io ((self OMPatch) (elem OMIn))
  (unless (index elem) ;; for instance when the input is loaded, the index is already set
    (let ((inputs (remove elem (get-inputs self))))
      (setf (index elem)
            (if inputs ;; index is +1 of the max existing indices
                (1+ (apply #'max (mapcar 'index inputs)))
              1)))))

(defmethod register-patch-io ((self OMPatch) (elem OMOut))
  (unless (index elem)
    (setf (index elem) (length (get-outputs self)))))

(defmethod unregister-patch-io ((self OMPatch) (elem OMIn))
  (loop for inp in (get-inputs self) do
        (when (> (index inp) (index elem))
          (setf (index inp) (1- (index inp))))))

(defmethod unregister-patch-io ((self OMPatch) (elem OMOut))
  (loop for out in (get-outputs self) do
        (when (> (index out) (index elem))
          (setf (index out) (1- (index out))))))

(defmethod omNG-add-element ((self OMPatch) (box OMInOutBox))
  (call-next-method)
  (register-patch-io self (reference box))
  ;(unless *loaading-stack* ;;; do not update if patch is being loaded: inputs are already OK
  (loop for item in (references-to self) do (update-from-reference item))
  t)

(defvar *erased-io* nil)
(defmethod omng-remove-element ((self OMPatch) (box OMInOutBox))
  (call-next-method)
  (unregister-patch-io self (reference box))
  (setf *erased-io* (reference box))
  (loop for item in (references-to self) do (update-from-reference item))
  (setf *erased-io* nil))
