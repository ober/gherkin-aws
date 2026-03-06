#!chezscheme
;; Build a native gerbil-aws binary.
;;
;; Usage: cd gherkin-aws && make binary

(import (chezscheme))

;; --- Helper: generate C header from binary file ---
(define (file->c-header input-path output-path array-name size-name)
  (let* ((port (open-file-input-port input-path))
         (data (get-bytevector-all port))
         (size (bytevector-length data)))
    (close-port port)
    (call-with-output-file output-path
      (lambda (out)
        (fprintf out "/* Auto-generated */~n")
        (fprintf out "static const unsigned char ~a[] = {~n" array-name)
        (let loop ((i 0))
          (when (< i size)
            (when (= 0 (modulo i 16)) (fprintf out "  "))
            (fprintf out "0x~2,'0x" (bytevector-u8-ref data i))
            (when (< (+ i 1) size) (fprintf out ","))
            (when (= 15 (modulo i 16)) (fprintf out "~n"))
            (loop (+ i 1))))
        (fprintf out "~n};~n")
        (fprintf out "static const unsigned int ~a = ~a;~n" size-name size))
      'replace)
    (printf "  ~a: ~a bytes~n" output-path size)))

;; --- Locate Chez install directory ---
(define chez-dir
  (or (getenv "CHEZ_DIR")
      (let* ((mt (symbol->string (machine-type)))
             (home (getenv "HOME"))
             (lib-dir (format "~a/.local/lib" home))
             (csv-dir
               (let lp ((dirs (guard (e (#t '())) (directory-list lib-dir))))
                 (cond
                   ((null? dirs) #f)
                   ((and (> (string-length (car dirs)) 3)
                         (string=? "csv" (substring (car dirs) 0 3)))
                    (format "~a/~a/~a" lib-dir (car dirs) mt))
                   (else (lp (cdr dirs)))))))
        (and csv-dir
             (file-exists? (format "~a/main.o" csv-dir))
             csv-dir))))

(unless chez-dir
  (display "Error: Cannot find Chez install dir. Set CHEZ_DIR.\n")
  (exit 1))

;; --- Locate gherkin runtime ---
(define gherkin-dir
  (or (getenv "GHERKIN_DIR")
      (let ((home (getenv "HOME")))
        (format "~a/mine/gherkin/src" home))))

(unless (file-exists? (format "~a/compat/types.so" gherkin-dir))
  (printf "Error: Cannot find gherkin runtime at ~a~n" gherkin-dir)
  (exit 1))

(printf "Chez dir:    ~a~n" chez-dir)
(printf "Gherkin dir: ~a~n" gherkin-dir)

(printf "
[1/6] Compiling all modules...
")
(parameterize ([compile-imported-libraries #t])
  (compile-program "aws.ss"))

(printf "[2/6] Using compiled program...
")
(system "cp aws.so gerbil-aws-all.so")

(printf "[3/6] Creating libs-only boot file...
")
(apply make-boot-file "gerbil-aws.boot" '("scheme" "petite")
  (append
    (list
      (format "~a/compat/types.so" gherkin-dir)
      (format "~a/compat/gambit-compat.so" gherkin-dir)
      (format "~a/runtime/util.so" gherkin-dir)
      (format "~a/runtime/table.so" gherkin-dir)
      (format "~a/runtime/c3.so" gherkin-dir)
      (format "~a/runtime/mop.so" gherkin-dir)
      (format "~a/runtime/error.so" gherkin-dir)
      (format "~a/runtime/hash.so" gherkin-dir)
      (format "~a/runtime/syntax.so" gherkin-dir)
      (format "~a/runtime/eval.so" gherkin-dir)
      (format "~a/reader/reader.so" gherkin-dir)
      (format "~a/compiler/compile.so" gherkin-dir)
      (format "~a/boot/gherkin.so" gherkin-dir)
    )
    (map (lambda (m) (format "src/compat/~a.so" m))
      '(json sugar sort getopt misc format gambit))
    (map (lambda (m) (format "src/gerbil-aws/~a.so" m))
      '(aws-creds aws-xml aws-api aws-json-api ec2-params ec2-params-test ec2-xml ec2-xml-test ec2-api ec2-instances ec2-images ec2-security-groups ec2-key-pairs ec2-vpcs ec2-subnets ec2-volumes ec2-snapshots ec2-addresses ec2-network-interfaces ec2-route-tables ec2-internet-gateways ec2-nat-gateways ec2-tags ec2-regions ec2-launch-templates s3-xml s3-xml-test s3-api s3-buckets s3-objects sts-api sts-operations iam-api iam-users iam-groups iam-roles iam-policies iam-access-keys lambda-api lambda-functions logs-api logs-operations dynamodb-api dynamodb-operations sns-api sns-operations sqs-api sqs-operations cfn-api cfn-stacks cloudwatch-api cloudwatch-operations rds-api rds-db-instances elbv2-api elbv2-operations compute-optimizer-api compute-optimizer-operations cost-optimization-hub-api cost-optimization-hub-operations ssm-api ssm-operations ssm-session cli-format))))

(printf "[4/6] Embedding boot files + program as C headers...
")
(file->c-header "gerbil-aws-all.so" "gerbil_aws_program.h"
                "gerbil_aws_program_data" "gerbil_aws_program_size")
(file->c-header (format "~a/petite.boot" chez-dir) "gerbil_aws_petite_boot.h"
                "petite_boot_data" "petite_boot_size")
(file->c-header (format "~a/scheme.boot" chez-dir) "gerbil_aws_scheme_boot.h"
                "scheme_boot_data" "scheme_boot_size")
(file->c-header "gerbil-aws.boot" "gerbil_aws_app_boot.h"
                "gerbil_aws_app_boot_data" "gerbil_aws_app_boot_size")

(printf "[5/6] Compiling and linking...
")
(let ((cmd (format "gcc -c -O2 -o gerbil-aws-main.o gerbil-aws-main.c -I~a -I. -Wall 2>&1" chez-dir)))
  (unless (= 0 (system cmd))
    (display "Error: C compilation failed\n")
    (exit 1)))
(let ((cmd (format "gcc -rdynamic -o gerbil-aws gerbil-aws-main.o -L~a -lkernel -llz4 -lz -lm -ldl -lpthread -luuid -lncurses -Wl,-rpath,~a"
             chez-dir chez-dir)))
  (printf "  ~a~n" cmd)
  (unless (= 0 (system cmd))
    (display "Error: Link failed\n")
    (exit 1)))

(printf "[6/6] Cleaning up...
")
(for-each (lambda (f)
            (when (file-exists? f) (delete-file f)))
  '("gerbil-aws-main.o" "gerbil_aws_program.h"
    "gerbil_aws_petite_boot.h" "gerbil_aws_scheme_boot.h" "gerbil_aws_app_boot.h"
    "gerbil-aws-all.so" "aws.so" "aws.wpo" "gerbil-aws.boot"))

(printf "
========================================
")
(printf "Build complete!

")
(printf "  Binary: ./gerbil-aws  (~a KB)
"
  (quotient (file-length (open-file-input-port "gerbil-aws")) 1024))
