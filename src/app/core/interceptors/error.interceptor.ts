import { HttpInterceptorFn } from "@angular/common/http";
import { catchError, throwError } from "rxjs";

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
    return next(req).pipe(
        catchError((err: any) => {
            // Ne pas recharger pour les erreurs 401 sur /login (laisser le composant gérer)
            if (err.status === 401 && !req.url.includes('/login')) {
                // auto logout if 401 response returned from api
                location.reload();
            }

            const error = err.error.detail || err.statusText;
            return throwError(() => error);
        })
    );
};