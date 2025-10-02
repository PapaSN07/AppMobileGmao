import { HttpInterceptorFn } from "@angular/common/http";
import { catchError, throwError } from "rxjs";

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
    return next(req).pipe(
        catchError((err: any) => {
            if (err.status === 401) {
                // auto logout if 401 response returned from api
                location.reload();
            }

            const error = err.error.message || err.statusText;
            return throwError(() => error);
        })
    );
};