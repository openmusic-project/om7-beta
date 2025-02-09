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

;;;=================
;;; SOUND OBJECT
;;;=================


(in-package :om)

(omNG-make-package
 "Audio"
 :container-pack *om-package-tree*
 :doc "Sound/DSP objects and support"
 :classes '(sound)
 :functions '(sound-dur sound-dur-ms sound-samples save-sound)
 :subpackages (list (omNG-make-package
                     "Processing"
                     :functions '(sound-silence
                                  sound-cut sound-fade
                                  sound-mix sound-seq
                                  sound-normalize sound-gain
                                  sound-mono-to-stereo sound-to-mono sound-stereo-pan
                                  sound-merge sound-split sound-resample
                                  sound-loop sound-reverse
                                  ))
                    (omNG-make-package
                     "Analysis"
                     :functions '(sound-rms sound-transients))
                    (omNG-make-package
                     "Conversions"
                     :functions '(lin->db db->lin samples->sec sec->samples ms->sec sec->ms))
                    (omNG-make-package
                     "Tools"
                     :functions '(adsr)))
 )


